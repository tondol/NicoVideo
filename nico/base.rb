# -*- coding: utf-8 -*-

####################################
# Base
####################################

module Nicovideo
  
  # constant values
  BASE_URL   = 'http://www.nicovideo.jp'
  BASE_HOST  = 'www.nicovideo.jp'
  WATCH_PATH = '/watch/'
  
  # proxy configuration
  PROXY_HOST = nil
  PROXY_PORT = 3128
  
  # error classes
  class AuthenticationError   < StandardError; end
  class VideoNotFoundError    < StandardError; end
  class AccessLockedError     < StandardError; end
  class UnavailableVideoError < StandardError; end
  
  class Base
    
    LOGIN_HOST = 'secure.nicovideo.jp'
    LOGIN_PATH = '/secure/login?site=niconico'
    
    ####################################
    # login operations
    ####################################
    
    def initialize(mail=nil, password=nil)
      @mail      = mail
      @password  = password
      @session   = nil
      @videopage = nil
      @logged_in = false
      self
    end
    
    def login(mail=nil, password=nil)
      unless logged_in?
        @mail     ||= mail
        @password ||= password
        
        https = Net::HTTP::Proxy(PROXY_HOST, PROXY_PORT).new(LOGIN_HOST, 443)
        https.use_ssl = true
        https.ssl_version = :SSLv3
        https.verify_mode = OpenSSL::SSL::VERIFY_NONE
        https.start {|w|
          body = "mail_tel=#{@mail}&password=#{@password}"
          response = w.post(LOGIN_PATH, body)
          response['Set-Cookie'] =~ /(user_session=user_session_\w+)/
          @session = $1 || nil
        }
        @logged_in = true
      end
      # raise exception
      raise AuthenticationError.new unless @session
      self
    end
    
    def logged_in?()
      @logged_in
    end
    
    ####################################
    # sub class operations
    ####################################
    
    def watch(video_id)
      videopage = Videopage.new(@session, video_id)
      yield videopage if block_given?
      videopage
    end
    
    def mylist(mylist_id)
      mylist = Mylist.new(@session, mylist_id)
      yield mylist if block_given?
      mylist
    end
    
    def deflist
      deflist = Deflist.new(@session)
      yield deflist if block_given?
      deflist
    end

    def channel(channel_id)
      channel = Channel.new(@session, channel_id)
      yield channel if block_given?
      channel
    end
  end
  
  ####################################
  # dummy operations
  ####################################
  
  def Nicovideo.new(mail, password)
    Base.new(mail, password)
  end
  
  def Nicovideo.login(mail, password)
    Base.new(mail, password).login
  end
end
