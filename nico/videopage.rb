# -*- coding: utf-8 -*-

####################################
# Videopage
####################################

module Nicovideo
  class Videopage
    def initialize(session, video_id)
      @video_id = video_id
      @session  = session
      @url      = BASE_URL + WATCH_PATH + @video_id
      @thumb    = nil
      @params   = nil
      @source   = nil
      @history  = nil
    end
    
    attr_reader :video_id, :url
    
    ####################################
    # thumb infomations
    ####################################
    
    def title
      get_thumb.elements['title'].text
    end
    
    def description
      get_thumb.elements['description'].text
    end
    
    def published_at
      date = get_thumb.elements['first_retrieve'].text
      Time.parse(date)
    end
    
    def length
      pattern = %r!(\d+):(\d+)!
      get_thumb.elements['length'].text =~ pattern
      minute = $1.to_i
      second = $2.to_i
      minute * 60 + second
    end
    
    def view_counter
      get_thumb.elements['view_counter'].text.to_i
    end
    
    def comment_num
      get_thumb.elements['comment_num'].text.to_i
    end
    
    def mylist_counter
      get_thumb.elements['mylist_counter'].text.to_i
    end
    
    def tags
      tags = []
      get_thumb.elements.each('tags') {|elem|
        next if elem.attributes['domain'] != 'jp'
        elem.elements.each('tag') {|tag| tags << tag.text }
      }
      tags
    end
    
    def type
      params = get_params
      video_uri = URI.decode(params['url'])
      pattern = %r!^http://.*\.nicovideo\.jp/smile\?(.*?)=.*$!
      video_uri =~ pattern
      case $1
      when 'm'
        "mp4"
      when 's'
        "swf"
      else
        "flv"
      end
    end
    
    ####################################
    # body
    ####################################
    
    def video
      params = get_params
      uri = URI.parse(URI.decode(params['url']))
      
      http = Net::HTTP::Proxy(PROXY_HOST, PROXY_PORT)
      http.start(uri.host, uri.port) {|w|
        cookie = "#{@session};#{@history}"
        buffer = String.new
        response = String.new
        # streaming download with buffer
        w.get(uri.request_uri, 'Cookie' => cookie) {|data|
          buffer << data
          response << data
          if buffer.size > BUFFER_SIZE then
            yield buffer.slice(0 ... BUFFER_SIZE) if block_given?
            buffer = buffer.slice(BUFFER_SIZE ... buffer.size)
          end
        }
        # remain buffer
        unless buffer.empty?
          yield buffer if block_given?
        end
        # return body
        response
      }
    end
    
    def thumbnail
      thumbnail_uri = get_thumb.elements['thumbnail_url'].text
      uri = URI.parse(thumbnail_uri)
      
      http = Net::HTTP::Proxy(PROXY_HOST, PROXY_PORT)
      http.start(uri.host, uri.port) {|w|
        buffer = String.new
        response = String.new
        # streaming download with buffer
        w.get(uri.request_uri, 'Cookie' => @session) {|data|
          buffer << data
          response << data
          if buffer.size > BUFFER_SIZE then
            yield buffer.slice(0 ... BUFFER_SIZE) if block_given?
            buffer = buffer.slice(BUFFER_SIZE ... buffer.size)
          end
        }
        # remain buffer
        unless buffer.empty?
          yield buffer if block_given?
        end
        # return body
        response
	    }
    end
    
    def comments(num=500)
      params = get_params
      uri = URI.parse(URI.decode(params['ms']))
      
      http = Net::HTTP::Proxy(PROXY_HOST, PROXY_PORT)
      http.start(uri.host, uri.port) {|w|
        cookie = "#{@session};#{@history}"
        thread_id = params['thread_id']
        body = %!<thread res_from="-#{num}" version="20061206" thread="#{thread_id}" />!
        response = w.post(uri.request_uri, body, 'Cookie' => cookie)
        response.body
      }
    end
    
    ####################################
    # utilities
    ####################################
    
    private
    def get_params
      # with cache
      return @params if @params
      
      http = Net::HTTP::Proxy(PROXY_HOST, PROXY_PORT)
      http.start(BASE_HOST, 80) {|w|
        request = WATCH_PATH + @video_id
        response = w.get(request, 'Cookie' => @session)
        @history = $1 if response['Set-Cookie'] =~ /(nicohistory=[^;]+)/
        @source = response.body
      }
      
      http.start(FLAPI_HOST, 80) {|w|
        request = GETFLV_PATH + @video_id + GETFLV_QUERY
        response = w.get(request, 'Cookie' => @session)
        array = response.body.split(/&/).map {|e| e.split(/=/, 2) }
        hash = Hash[*array.flatten]
        # raise exception
        raise AccessLockedError.new if hash['error']
        raise UnavailableVideoError.new if hash['url'].empty?
        @params = hash
      }
    end
    
    def get_thumb
      # with cache
      return @thumb if @thumb
      
      http = Net::HTTP::Proxy(PROXY_HOST, PROXY_PORT)
      http.start(EXT_HOST, 80) {|w|
        request = GETTHUMBINFO_PATH + @video_id
        response = w.get(request, 'Cookie' => @session)
        document = REXML::Document.new(response.body)
        # raise exception
        status = document.elements['nicovideo_thumb_response'].attributes['status']
        raise VideoNotFoundError.new if status != "ok"
        @thumb = document.elements['nicovideo_thumb_response/thumb']
      }
    end
  end
end
