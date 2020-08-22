require "lib/custom_markdown"
require "rest-client"

SIZES = CustomMarkdown::SIZES
BASE_URL = "https://matsimitsu.com".freeze
MICROBLOG_URL = "https://matsimitsu.com/.netlify/functions/microblog".freeze
TOKEN = ENV["TOKEN"].freeze

###
# Page options, layouts, aliases and proxies
###

# Per-page layout changes:
#
# With no layout
page "/*.xml", :layout => false
page "/*.json", :layout => false
page "/*.txt", :layout => false

# With alternative layout
# page "/path/to/file.html", layout: :otherlayout

# Proxy pages (http://middlemanapp.com/basics/dynamic-pages/)
# proxy "/this-page-has-no-template.html", "/template-file.html", locals: {
#  which_fake_page: "Rendering a fake page with a local variable" }

###
# Syntax highlight
###

activate :syntax
activate :livereload

###
# Blog
###

activate :blog do |blog|
  blog.name = "blog"
  blog.prefix = "blog"
  blog.permalink = "{title}.html"
  blog.sources = "{title}.html"
  blog.layout = "blog"
end

###
# Trips
###

activate :blog do |blog|
  blog.name = "trips"
  blog.prefix = "trips"
  blog.permalink = "{trip}/{title}.html"
  blog.sources = "{trip}/{title}.html"
  blog.layout = "trip"
  blog.publish_future_dated = true
end

###
# Notes
###

activate :blog do |blog|
  blog.name = "notes"
  blog.prefix = "notes"
  blog.permalink = "{title}.html"
  blog.sources = "{title}.html"
  blog.layout = "notes"
end

## Generate index pages for each trip
data[:trips].each do |trip|
  proxy(
    "/trips/#{trip[:slug]}/index.html", "/trip.html",
    :locals => {:trip => trip},
    :ignore => true
  )
end

## Fancy urls
activate :directory_indexes

# Markdown options
set :markdown_engine, :redcarpet
set :markdown, CustomMarkdown::OPTIONS.merge(:renderer => CustomMarkdown)

## Rss Feed
page "/feed.xml", :layout => false


# CSS
set :css_dir, 'stylesheets'
set :js_dir, 'javascripts'
set :images_dir, 'assets/images'

# Reload the browser automatically whenever files change
# configure :development do
#   activate :livereload
# end

# Netlify Redirects
ready do
  proxy "_redirects", "netlify-redirects", :ignore => true
end

# Methods defined in the helpers block are available in templates
helpers do

  def trip_url(trip)
    "/trips/#{trip}"
  end

  def breadcrumbs(page)
    hierarchy = [page]
    hierarchy.unshift hierarchy.first.parent while hierarchy.first.parent
    hierarchy.shift
    return unless hierarchy.any?

    crumbs = hierarchy.collect do |p|
      <<~HTML
        <li class="flex items-center">
        <svg class="fill-current opacity-50 w-3 h-3 mx-3" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 512"><path d="M285.476 272.971L91.132 467.314c-9.373 9.373-24.569 9.373-33.941 0l-22.667-22.667c-9.357-9.357-9.375-24.522-.04-33.901L188.505 256 34.484 101.255c-9.335-9.379-9.317-24.544.04-33.901l22.667-22.667c9.373-9.373 24.569-9.373 33.941 0L285.475 239.03c9.373 9.372 9.373 24.568.001 33.941z"/></svg>
          #{link_to(page_title(p), p.url)}
        </li>
      HTML
    end.join

    <<~HTML
      <nav class="text-gray-6 hidden lg:block" aria-label="Breadcrumb">
        <ol class="list-none p-0 inline-flex">
          #{crumbs}
        </ol>
    </nav>
    HTML
  end

  def page_title(page)
    return page.data.breadcrumb if page.data.breadcrumb

    return page.locals[:trip][:title] if page.locals && page.locals[:trip]

    page.data.title
  end

  def scaled_image(url, alt = nil, class_names = "", image_class_names = "w-full")
    return unless url

    srcset = SIZES.map do |size|
      ext = File.extname(url)
      "#{url.gsub(ext, "-#{size}#{ext}")} #{size}w"
    end
    %(<figure class="ScaledImage #{class_names}">
      <img
        class="#{image_class_names}"
        alt="#{alt || "Hero Header"}"
        src="#{srcset[0]}"
        srcset="#{srcset.join(", ")}"
        sizes="360px" />
    </figure>)
  end

  def sized_image(url, size)
    ext = File.extname(url)
    url.gsub(ext, "-#{size}#{ext}").to_s
  end

  def trip_articles(trip)
    blog("trips")
      .articles
      .select { |a| a.data[:trip] == trip }
      .sort_by(&:date)
  end

  def trip_image_groups(trip)
    articles = trip_articles(trip)
    return [] if articles.length <= 1

    res = articles.each_slice((articles.length / 2).floor).to_a.first(2)
    res
  end

  def countries
    data[:trips].flat_map { |t| t[:countries] }.uniq.map { |code| country(code) }
  end

  def continents_with_countries
    result = Hash.new { |h, k| h[k] = [] }
    countries.each do |country|
      result[country.subregion] << country
    end
    result
  end

  def current_trip
    return nil unless current_article && current_article.data[:trip]

    data[:trips].find { |t| t[:slug] == current_article.data[:trip] }
  end

  def upcoming_trip?(trip, date = Time.zone.today)
    date < Date.parse(trip[:start])
  end

  def trip_article?(article, other_article)
    return false if !article || !other_article

    article.data[:trip] == other_article.data[:trip]
  end

  def date_range(start_date, end_date = nil, separator = "-", classes = "")
    date_string = start_date.clone.to_s
    if end_date.present? && start_date != end_date
      date_string << " #{separator} #{end_date}"
    end

    %(
      <div class="#{classes}">#{date_string}</div>
    )
  end

  def days_in_words(start_date, end_date)
    (Date.parse(end_date) - Date.parse(start_date)).to_i
  end

  def base_url
    BASE_URL
  end

  def country(short)
    ISO3166::Country[short]
  end

  def svg_map(wanted, highlight = [], default_class = "fill-gray", highlight_class = "fill-yellow")
    svg = File.read("./data/#{wanted}.svg")
    highlight = Array(highlight)
    regex = /class=\"sm_state_(?<state>\w+)\"/
    new_svg = svg.lines.map do |line|
      match = line.match(regex)
      if match && highlight.include?(match[:state])
        line.gsub(regex, %(class="sm_state_#{match[:state]} #{highlight_class}))
      elsif match
        line.gsub(regex, %(class="sm_state_#{match[:state]} #{default_class}))
      else
        line
      end
    end
    new_svg.join
  end

  def trip_data(name)
    data[current_trip.slug][name] || []
  end

  def post_data(name)
    current_article.data[name] || []
  end

  def location(title)
    location = post_data(:locations).find { |h| h.title == title } ||
      trip_data(:locations).find { |h| h.title == title }
    return unless location

    <<~HTML
      <div class="Location">
        <h2>
          <span>#{location.title}</span>
          <i class="fas fa-map-marked-alt"></i>
        </h2>
      </div>
    HTML
  end

  def hotel(name)
    hotel = trip_data(:hotels).find { |h| h.name == name }
    return unless hotel

    formatted_price = format("%.2f", hotel.price).tr(".", ",")
    <<~HTML
      <div class="Hotel">
        <a href="#{hotel.url}">
          <img src="#{hotel.image}"/>
          <div>
            <h2>#{hotel.name}</h2>
            <small>#{hotel.address}</small>
            <p>#{current_trip.solo ? "I" : "We"} paid: <strong>&euro; #{formatted_price}</strong> per night</p>
            <p>#{hotel.description.strip}</p>
            <div class="Button secondary">View on Booking.com</div>
          </div>
        </a>
      </div>
    HTML
  end

  def flight(from_to)
    flight = trip_data(:flights).find { |f| f.name == from_to }
    return unless flight

    from_airport = Airports.find_by_iata_code(flight.from.code)
    from_time = Time.parse(flight.from.time).strftime("%H:%M")

    to_airport = Airports.find_by_iata_code(flight.to.code)
    to_time = Time.parse(flight.to.time).strftime("%H:%M")

    duration = Time.at(flight.duration).utc.strftime("%H:%M")

    <<~HTML
      <div class="Flight Container narrow">
        <div class="row">
          <h2 class="row">
            <span>
              #{flight.company}
              <small>flight</small>
              #{flight.number}
            </span>
            <small class="aircraft">
            #{flight.aircraft}
          </small>
          </h2>
        </div>
        <div class="row">
          <div class="from">
            <h3 class="H-Large">#{from_airport.iata}</h3>
            <p>#{from_airport.city}</p>
            <small>#{from_time}</small>
          </div>
          <div class="duration"><time>#{duration}</time></div>
          <div class="to">
            <h3 class="H-Large">#{to_airport.iata}</h3>
            <p>#{to_airport.city}</p>
            <small>#{to_time}</small>
          </div>
        </div>
      </div>
    HTML
  end
end

# Build-specific configuration
configure :build do
  # Minify CSS on build
  # activate :minify_css

  # Minify Javascript on build
  # activate :minify_javascript
end

activate :external_pipeline,
  :name => :webpack,
  :command => build? ? "yarn build" : "yarn dev",
  :source => ".tmp/dist",
  :latency => 1
