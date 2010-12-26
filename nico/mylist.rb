# -*- coding: utf-8 -*-

####################################
# Mylist
####################################

module Nicovideo
  class Mylist
    
    MYLIST_PATH = '/my/mylist'
    MYLIST_API_PATH = '/api/mylist/'
    
    def initialize(session, mylist_id)
      @session   = session
      @mylist_id = mylist_id
      @token     = nil
    end
    
    attr_reader :mylist_id, :url, :feed_url
    
    ####################################
    # api
    ####################################
    
    def list
      query = build_query({
        'token' => get_token,
        'group_id' => @mylist_id,
      })
      call_api("list", query)
    end
    
    def add(video_id, description="")
      query = build_query({
        'token' => get_token,
        'group_id' => @mylist_id,
        'item_type' => 0,
        'item_id' => video_id,
        'description' => description,
      })
      call_api("add", query)
    end
    
    def update(item_id, descrition="")
      query = build_query({
        'token' => get_token,
        'group_id' => @mylist_id,
        'item_type' => 0,
        'item_id' => video_id,
        'description' => description,
      })
      call_api("update", query)
    end
    
    def remove(item_ids)
      query = build_query({
        'token' => get_token,
        'group_id' => @mylist_id,
        'id_list' => item_ids,
      })
      call_api("remove", query)
    end
    
    def move(group_id, item_ids)
      query = build_query({
        'token' => get_token,
        'group_id' => @mylist_id,
        'target_group_id' => group_id,
        'id_list' => item_ids,
      })
      call_api("move", query)
    end
    
    def copy(group_id, item_ids)
      query = build_query({
        'token' => get_token,
        'group_id' => @mylist_id,
        'target_group_id' => group_id,
        'id_list' => item_ids,
      })
      call_api("copy", query)
    end
    
    ####################################
    # utilities
    ####################################
    
    private
    def call_api(command, query)
      response = nil
      http = Net::HTTP::Proxy(PROXY_HOST, PROXY_PORT)
      http.start(BASE_HOST, 80) {|w|
        request = MYLIST_API_PATH + command + "?" + query
        response = w.get(request, 'Cookie' => @session)
      }
      JSON.parse(response.body)
    end
    
    private
    def get_token
      # with cache
      return @token if @token
      
      http = Net::HTTP::Proxy(PROXY_HOST, PROXY_PORT)
      http.start(BASE_HOST, 80) {|w|
        request = MYLIST_PATH
        response = w.get(request, 'Cookie' => @session)
        body = response.body.force_encoding("utf-8")
        @token = $1 if body =~ /NicoAPI\.token = "([0-9a-f-]+)"/;
      }
      
      # return token
      @token
    end
    
    private
    def build_query(params)
      query = []
      params.each_pair {|key, value|
        if value.instance_of?(Array) then
          value.each {|v|
            query << (key + "[0][]=" + URI.escape(v))
          }
        else
          query << (key + "=" + URI.escape(value.to_s))
        end
      }
      query.join("&")
    end
  end
end
