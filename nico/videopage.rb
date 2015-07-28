# -*- coding: utf-8 -*-

####################################
# Videopage
####################################

module Nicovideo
  class Videopage

    EXT_HOST   = 'ext.nicovideo.jp'
    FLAPI_HOST = 'flapi.nicovideo.jp'
    
    GETFLV_PATH       = '/api/getflv/'
    GETTHUMBINFO_PATH = '/api/getthumbinfo/'
    BUFFER_SIZE       = 1024*1024
    
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
    # thumb infomation
    ####################################
    
    def title
      get_thumb.elements['title'].text
    end
    
    def description
      get_thumb.elements['description'].text
    end
    
    def first_retrieve
      date = get_thumb.elements['first_retrieve'].text
      Time.iso8601(date).getlocal
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
      # return tags
      tags
    end
    
    def type
      params = get_params
      video_uri = URI.decode(params['url'])
      video_uri =~ %r!^http://.*\.nicovideo\.jp/smile\?(.*)=.*$!
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
      response = String.new
      video_with_block {|data|
        response << data
        yield data if block_given?
      }
      response
    end

    def video_with_block
      params = get_params
      uri = URI.parse(URI.decode(params['url']))
      
      http = Net::HTTP::Proxy(PROXY_HOST, PROXY_PORT)
      http.start(uri.host, uri.port) {|w|
        cookie = "#{@session};#{@history}"
        # streaming download
        w.get(uri.request_uri, 'Cookie' => cookie) {|data|
          yield data if block_given?
        }
      }
    end

    def thumbnail
      thumbnail_uri = get_thumb.elements['thumbnail_url'].text
      uri = URI.parse(thumbnail_uri)
      
      http = Net::HTTP::Proxy(PROXY_HOST, PROXY_PORT)
      http.start(uri.host, uri.port) {|w|
        response = String.new
        # streaming download
        w.get(uri.request_uri, 'Cookie' => @session) {|data|
          response << data
          yield data if block_given?
        }
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
        request = GETFLV_PATH + @video_id
        response = w.get(request, 'Cookie' => @session)
        array = response.body.split(/&/).map {|e| e.split(/=/, 2) }
        hash = Hash[*array.flatten]
        # raise exception
        raise AccessLockedError.new if hash['error']
        raise UnavailableVideoError.new if hash['closed']
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
        thumb_response = document.elements['nicovideo_thumb_response']
        raise VideoNotFoundError.new if thumb_response.attributes['status'] != "ok"
        @thumb = thumb_response.elements['thumb']
      }
    end
  end
end
