require "fastimage"
require "json"
require "rest-client"

TOKEN = ENV["SITE_TOKEN"]
PUBLIC_URL = "https://d3khpbv2gxh34v.cloudfront.net/r/notes/"
PRESIGN_URL = "https://matsimitsu.com/.netlify/functions/image_upload_url"

path = ARGV[0]
filename = File.basename(path)

url = JSON.parse(RestClient.post(PRESIGN_URL, {:fileName => filename, :fileType => "image/jpeg", :token => TOKEN }.to_json, {content_type: :json, accept: :json}).body)["uploadURL"]
puts url
begin
  RestClient.put(url, File.new(path, "rb"), :headers => {:content_type=>"image/jpeg"})
rescue => e
  puts e.inspect
  puts e.response.body.inspect
end
width, height = FastImage.size(path)
ratio = (width.to_f / height.to_f).round(2)

puts %Q(![#{filename}](#{PUBLIC_URL}#{filename.gsub(".jpg", "-720.jpg")} "#{ratio}"))
