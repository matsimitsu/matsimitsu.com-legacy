#!/usr/bin/env ruby
require "fileutils"

path      = ARGV[0]
width     = ARGV[1] || 1080
height    = ARGV[2] || 720

basename = File.basename(path).split(".")[0]
FileUtils.mkdir_p basename

`ffmpeg -i "#{path}" -vf scale=#{width}:#{height} -c:v libx264 -pix_fmt yuv420p -movflags faststart -g 30 -an "#{basename}/#{basename}.mp4"`
`ffmpeg -i "#{path}" -vf scale=#{width}:#{height} -b 1500k -vcodec libvpx -acodec libvorbis -ab 160000 -f webm -g 30 -an "#{basename}/#{basename}.webm"`
`ffmpeg -i "#{path}" -vf scale=#{width}:#{height} -b 1500k -vcodec libtheora -acodec libvorbis -ab 160000 -g 30 -an "#{basename}/#{basename}.ogv"`
`ffmpeg -ss 00:00:00 -i "#{path}" -vframes 1 -q:v 2 "#{basename}/#{basename}.jpg"`
w, h = `ffprobe -v error -show_entries stream=display_aspect_ratio -of default=nw=1:nk=1  "./#{basename}/#{basename}.mp4"`.split(":")
puts %(>[#{basename} video](#{basename}.mp4 "#{(w.to_f / h.to_f).round(2)}"))
