require "aws-sdk-s3"
require "fastimage"

BUCKET = "matsimitsu"
BASE_PATH = "original"
PUBLIC_URL = "https://d3khpbv2gxh34v.cloudfront.net/p/"
S3_KEY = ENV["S3_KEY_MATSIMITSU"]
S3_SECRET = ENV["S3_SECRET_MATSIMITSU"]
S3_BUCKET =  "eu-central-1"
local_path = ARGV[0]
remote_path = ARGV[1]

puts S3_KEY
s3 = Aws::S3::Resource.new(
  :region => S3_BUCKET,
  :credentials => Aws::Credentials.new(S3_KEY, S3_SECRET)
)

photos = Dir.glob(File.join(local_path, "*.jpg")).sort_by {|f| File.mtime(f) }

puts "Uploading #{photos.length} photos"
puts "=" * 80
photos.each do |photo|
  filename = File.basename(photo)
  object_name = File.join(BASE_PATH, remote_path, filename)
  width, height = FastImage.size(photo)
  ratio = (width.to_f / height.to_f).round(2)
  puts object_name.inspect
  url = File.join(PUBLIC_URL, remote_path, filename.gsub(".jpg", "-360.jpg"))
  obj = s3.bucket(BUCKET).object(object_name)
  obj.upload_file(photo)
  puts %{![#{filename}](#{url} "#{ratio}") \n\n}
end
