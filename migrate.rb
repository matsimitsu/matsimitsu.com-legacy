require "graphql/client"
require "graphql/client/http"
require "yaml"
require "open-uri"

BASE_URL = "https://d3khpbv2gxh34v.cloudfront.net"
HTTP = GraphQL::Client::HTTP.new("https://api.daybreakers.co/graphql")
Schema = GraphQL::Client.load_schema(HTTP)
Client = GraphQL::Client.new(:schema => Schema, :execute => HTTP)

AllQuery = Client.parse <<-'GRAPHQL'
  query {
    user(username: "matsimitsu") {
      id
      name
      isViewer
      username
      trips {
        id
        title
        subtitle
        startDate
        endDate
        photoCount
        posts {
          id
        }
      }
      __typename
    }
  }
GRAPHQL

PostQuery = Client.parse <<-'GRAPHQL'
  query ($id: String!) {
    user(username: "matsimitsu") {
      post(id: $id) {
        title
        subtitle
        startDate
        endDate
        published
        photos {
          url
          ratio
          id
        }
        locations {
          title
          lat
          lng
        }
        header {
          ratio
          id
          url
          width
          height
          __typename
        }
        sections {
          ... on TextSection {
            id
            title
            body
            index
            __typename
          }
          ... on PhotoRowSection {
            id
            index
            items {
              id
              index
              photo {
                id
                url
                ratio
                width
                height
                __typename
              }
              __typename
            }
            __typename
          }
          ... on HeroSection {
            id
            index
            photo {
              id
              url
              ratio
              width
              height
              __typename
            }
            __typename
          }
          __typename
        }
        __typename
      }
    }
  }
GRAPHQL

def slug(str)
  str.downcase.gsub(/[^a-zA-Z-0-9\- ]/, " ").split.join(" ").tr(" ", "-")
end

def photo_path(trip, post, photo)
  File.join(BASE_URL, "p", slug(trip.title), slug(post.title), "#{photo.id}.jpg")
end

def write_post_to_markdown(post, trip)
  markdown = ""

  markdown << {
    "title" => post.title,
    "subtitle" => post.subtitle,
    "date" => post.start_date,
    "end_date" => post.end_date,
    "image" => photo_path(trip, post, post.header),
    "trip" => slug(trip.title),
    "locations" => post.locations.map { |l| l.to_h }
  }.to_yaml
  markdown << "---\n\n"

  post.sections.each do |section|
    case section.__typename.to_s
    when "TextSection"
      markdown << "###{section.title}\n\n" if (section.title || "").length > 0
      markdown << "#{section.body}\n"
    when "PhotoRowSection"
      section.items.sort_by {|i| i.index }.each do |item|
        markdown << "![#{item.id}](#{photo_path(trip, post, item.photo)} \"#{item.photo.ratio}\")\n"
      end
    when "HeroSection"
      markdown << "![hero|#{section.photo.id}](#{photo_path(trip, post, section.photo)} \"#{section.photo.ratio}\")\n"
    end
    markdown << "\n"
  end

  post_path = File.join("./source/trips", slug(trip.title), "#{slug(post.title)}.html.md")
  puts "Writing post to #{post_path}"
  File.write(post_path, markdown)
end

def download_photos(post, trip)
  post_path = File.join("./photos", slug(trip.title), slug(post.title))

  puts "Creating directory: #{post_path}"
  FileUtils.mkdir_p(post_path)

  download_photo(File.join(post_path, "#{post.header.id}.jpg"), post.header.url)

  post.photos.each do |photo|
    download_photo(File.join(post_path, "#{photo.id}.jpg"), photo.url)
  end
end

def download_photo(photo_path,  url)
  return if File.exists?(photo_path)
  puts "Downloading #{url} to #{photo_path}"
  File.open(photo_path, "wb") do |file|
    file.write open(url).read
  end
end

result = Client.query(AllQuery)

trips = result.data.user.trips.map do |trip|
  {
    "title" => trip.title,
    "subtitle" => trip.subtitle,
    "excerpt" => "",
    "start" => trip.start_date,
    "end" => trip.end_date,
    "layout" => "trip_overview",
    "slug" => slug(trip.title),
    "photo_count" => trip.photo_count
  }
end

puts "Writing trips to /data/trips.yml"
File.write("./data/trips.yml", trips.reverse.to_yaml)

result.data.user.trips.each do |trip|
  path = File.join("./source/trips", slug(trip.title))
  puts "Creating: #{path}"
  FileUtils.mkdir_p path

  trip.posts.each do |post_id|
    post = Client.query(PostQuery, :variables => { :id => post_id.id }).data.user.post

    download_photos(post, trip)

    write_post_to_markdown(post, trip)
  end
end
