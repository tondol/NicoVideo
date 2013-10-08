# -*- coding: utf-8 -*-

####################################
# Channel
####################################

module Nicovideo
  class Channel
    
    CHANNEL_HOST         = 'ch.nicovideo.jp'
    CHANNEL_PATH_PREFIX  = '/'
    CHANNEL_PATH_POSTIFX = '/video?rss=2.0'
    
    def initialize(session, channel_id)
      @session    = session
      @channel_id = channel_id
      @channel    = nil
    end

    attr_reader :channel_id
    
    ####################################
    # channel informations
    ####################################

    def creator
      get_channel.elements['dc:creator'].text
    end

    def pub_date
      date = get_channel.elements['pubDate'].text
      Time.rfc2822(date).getlocal
    end

    def items
      items = []
      get_channel.elements.each('item') {|item|
        link = item.elements['link'].text
        link =~ %r!^http://.*\.nicovideo\.jp/watch/(.*)$!
        items << Videopage.new(@session, $1)
      }
      # return videos
      items
    end
    
    ####################################
    # utilities
    ####################################
    
    private
    def get_channel
      # with cache
      return @rss if @rss

      http = Net::HTTP::Proxy(PROXY_HOST, PROXY_PORT)
      http.start(CHANNEL_HOST, 80) {|w|
        request = CHANNEL_PATH_PREFIX + @channel_id + CHANNEL_PATH_POSTFIX
        response = w.get(request, 'Cookie' => @session)
        document = REXML::Document.new(response.body)
        @channel = document.elements['rss/channel']
      }
    end
  end
end
