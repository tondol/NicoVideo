# -*- coding: utf-8 -*-

####################################
# Channel
####################################

module Nicovideo
  class ChannelItem
    def initialize(item)
      @rss = item
    end

    ####################################
    # item information
    ####################################

    def title
      @rss.elements['title'].text
    end

    def link
      @rss.elements['link'].text
    end

    def pub_date
      date = @rss.elements['pubDate'].text
      Time.rfc2822(date).getlocal
    end

    def video_id
      link =~ %r!^http://.*\.nicovideo\.jp/watch/(.*)$!
      $1
    end
  end

  class Channel
    
    CHANNEL_HOST         = 'ch.nicovideo.jp'
    CHANNEL_PATH_PREFIX  = '/'
    CHANNEL_PATH_POSTFIX = '/video?rss=2.0'
    
    def initialize(session, channel_id)
      @session    = session
      @channel_id = channel_id
      @channel    = nil
    end

    attr_reader :channel_id
    
    ####################################
    # channel information
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
        items << ChannelItem.new(item)
      }
      # return items
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
