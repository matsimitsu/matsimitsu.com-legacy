require "json"
require "rest-client"
require "exiftool_vendored"
require "exiftool"
require "yaml"

TOKEN = ENV["SITE_TOKEN"]
PUBLIC_URL = "https://d3khpbv2gxh34v.cloudfront.net/r/notes/"
PRESIGN_URL = "https://matsimitsu.com/.netlify/functions/image_upload_url"
MICROPUB_URL = "https://matsimitsu.com/.netlify/functions/micropub"

path = ARGV[0]
title = ARGV[1]
filename = File.basename(path)

e = Exiftool.new(path).to_hash
exif = {
  "aperture" => e[:aperture].to_s,
  "shutter_speed" => e[:shutter_speed].to_s,
  "iso" => e[:iso].to_s,
  "lens" => e[:lens].to_s,
  "make" => e[:make].to_s,
  "model" => e[:model].to_s,
  "lens_info" => e[:lens_info].to_s,
  "focal_length" => e[:focal_length].to_s,
  "created" => e[:date_time_created].to_s
}
ratio = (e[:image_width].to_f / e[:image_height].to_f).round(3)
url = JSON.parse(RestClient.post(
  PRESIGN_URL,
  {:dirName => "notes", :fileName => filename, :fileType => "image/jpeg", :token => TOKEN }.to_json,
  {content_type: :json, accept: :json}).body)["uploadURL"]
begin
  RestClient.put(url, File.new(path, "rb"), :headers => {:content_type=>"image/jpeg"})
rescue => e
  puts e.inspect
  puts e.response.body.inspect
end

markdown_content = <<~MARKDOWN
---
title: #{title}
date: #{e[:date_time_created].to_s}
category: photo
---

##{title}

![#{filename}](#{PUBLIC_URL}#{filename.gsub(".jpg", "-720.jpg")} "#{ratio}")

[exif: #{exif.to_json}]
MARKDOWN

puts markdown_content
exit
markdown_filename = "#{e[:date_time_created].to_date}-#{tite.gsub(/[\W]+/,"-")}"
begin
  RestClient.put(
    "#{MICROPUB_URL}?filename=#{markdown_filename}",
    {:properties => { :name => [title], :content => [content]}}.to_json,
    :authorization =>  "Bearer #{TOKEN}", :content_type => :json, :accept => :json)
rescue => e
  puts e.inspect
  puts e.response.body.inspect
end
