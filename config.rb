require "lib/custom_markdown"

SIZES = CustomMarkdown::SIZES
BASE_URL = "https://matsimitsu.com".freeze
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
set :css_dir, "stylesheets"

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

  def scaled_image(url, alt = nil, class_names = "")
    srcset = SIZES.map do |size|
      ext = File.extname(url)
      "#{url.gsub(ext, "-#{size}#{ext}")} #{size}w"
    end
    %(<figure class="ScaledImage #{class_names}">
      <img
        alt="#{alt || "Hero Header"}"
        src="#{srcset[0]}"
        srcset="#{srcset.join(", ")}"
        sizes="360px" />
    </figure>)
  end

  def sized_image(url, size)
    ext = File.extname(url)
    "#{url.gsub(ext, "-#{size}#{ext}")}"
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

  def current_trip
    return nil unless current_article && current_article.data[:trip]
    data[:trips].find { |t| t[:slug] == current_article.data[:trip] }
  end

  def trip_article?(article, other_article)
    return false if !article || !other_article
    article.data[:trip] == other_article.data[:trip]
  end

  def date_range(start_date, end_date = nil, separator = "-")
    date_string = "#{start_date}"
    if end_date.present? && start_date != end_date
      date_string << " #{separator} #{end_date}"
    end

    %(
      <div class="Dates">
        <span class="DateRange">#{date_string}</span>
      </div>
    )
  end

  def days_in_words(start_date, end_date)
    (Date.parse(end_date) - Date.parse(start_date)).to_i
  end

  def base_url
    BASE_URL
  end

  def svg_map(wanted, highlight = [])
    svg = File.read("./data/#{wanted}.svg")
    hightlight_selectors = Array(highlight).map do |hl|
      ".Map svg path.sm_state_#{hl}"
    end
    %(
      #{svg}
      <style>#{hightlight_selectors.join(", ")} { fill: var(--medium); }</style>
    )
  end
end

# Build-specific configuration
configure :build do
  # Minify CSS on build
  # activate :minify_css

  # Minify Javascript on build
  # activate :minify_javascript
end
