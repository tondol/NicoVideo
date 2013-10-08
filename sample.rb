#!/usr/local/bin/ruby
# -*- coding: utf-8 -*-

require 'yaml'

require_relative 'nico'

# 設定ファイルを読み込む
# config.ymlは予めconfig.yml.sampleを参考に作成する必要がある

config = YAML.load_file('config.yml')

# Nicovideoにログインする
# mailとpasswordは設定ファイルのものが使われる

nv = Nicovideo.login(config["mail"], config["password"])

# video_idの動画とそのサムネイルをダウンロードする

output_thumb_name = "thumb.jpg"
output_video_name_without_ext = "video"

nv.watch(config["video_id"]) {|video|
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

# from_mylist_idのマイリストのうち、
# マイリストコメントが"comment"である動画を
# to_mylist_idのマイリストに移動する

nv.mylist(config["from_mylist_id"]) {|mylist|
  item_ids = []
  mylist.list['mylistitem'].each {|item|
    if item['description'] == "comment" then
      item_ids << item['item_id']
    end
  }
  unless item_ids.empty? then
    mylist.move(config["to_mylist_id"], item_ids)
  end
}
