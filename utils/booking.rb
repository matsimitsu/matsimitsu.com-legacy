#!/usr/bin/env ruby
require 'rubygems'
require 'nokogiri'
require 'restclient'
require 'json'
require 'yaml'

url = ARGV[0] || 'https://www.booking.com/hotel/jp/mystays-premier-fujisan.html'

page = Nokogiri::HTML(RestClient.get(url))
json = JSON.parse(page.xpath('//script[@type="application/ld+json"]')[0])
lat,lng = CGI.parse(URI.parse(json['hasMap']).query)["center"].first.split(",").map(&:to_f)

yaml = [
  {
    'name'        => json['name'],
    'address'     => json['address']['streetAddress'],
    'image'       => json['image'],
    'url'         => json['url'] + "?aid=939121",
    'description' => json['description'],
    'lat'         => lat,
    'lng'         => lng
  }
].to_yaml
puts yaml
