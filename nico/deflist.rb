# -*- coding: utf-8 -*-

####################################
# Deflist
####################################

module Nicovideo
  class Deflist
    
    MYLIST_PATH = '/my/mylist'
    DEFLIST_API_PATH = '/api/deflist/'
    
    def initialize(session)
      @session  = session
      @token    = nil
    end
    
    ####################################
    # api
    ####################################
    
    def list
      query = build_query({
        'token' => get_token,
      })
      call_api("list", query)
    end
    
    def add(video_id, description="")
      query = build_query({
        'token' => get_token,
        'item_type' => 0,
        'item_id' => video_id,
        'description' => description,
      })
      call_api("add", query)
    end
    
    def update(item_id, description)
      query = build_query({
        'token' => get_token,
        'item_type' => 0,
        'item_id' => item_id,
        'description' => description,
      })
      call_api("update", query)
    end
    
    def remove(item_ids)
      query = build_query({
        'token' => get_token,
        'id_list' => item_ids,
      })
    end
    
    def move(group_id, item_ids)
      query = build_query({
        'token' => get_token,
        'target_group_id' => group_id,
        'id_list' => item_ids,
      })
      call_api("move", query)
    end
    
    def copy(group_id, item_ids)
      query = build_query({
        'token' => get_token,
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
        request = DEFLIST_API_PATH + command + "?" + query
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
