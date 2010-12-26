#!/usr/local/bin/ruby
# -*- coding: utf-8 -*-

require 'nico'

# ニコニコ動画にログイン

nv = Nicovideo.login("hosakanpo@gmx.net", "hosanoterrorism")

# 動画とサムネイルをダウンロード

video_id = "sm9"
output_thumb_name = "thumb.jpg"
output_video_name_without_ext = "video"

nv.watch(video_id) {|video|
  puts video.title
  puts video.description
  output_video_name = output_video_name_without_ext + "." + video.type
  File.open(output_thumb_name, "wb") {|f|
    f.write video.thumbnail
  }
  File.open(output_video_name, "wb") {|f|
    video.video {|buf|
      f.write buf
    }
  }
}

# あるマイリストのうち
# マイリストコメントが"comment"である動画を
# 別のマイリストに移動

from_mylist_id = "22811153"
to_mylist_id = "22811190"

nv.mylist(from_mylist_id) {|mylist|
  item_ids = []
  mylist.list['mylistitem'].each {|item|
    if item['description'] == "comment" then
      item_ids << item['item_id']
    end
  }
  unless item_ids.empty? then
    mylist.move(to_mylist_id, item_ids)
  end
}
