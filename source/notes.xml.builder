xml.instruct!
xml.feed "xmlns" => "http://www.w3.org/2005/Atom" do
  site_url = "https://matsimitsu.com/"
  xml.title "Matsimitsu"
  xml.subtitle "A blog by Robert Beekman"
  xml.id URI.join(site_url, blog("blog").options.prefix.to_s)
  xml.link "href" => URI.join(site_url, blog("blog").options.prefix.to_s)
  xml.link "href" => URI.join(site_url, current_page.path), "rel" => "self"
  xml.updated(blog("notes").articles.first.date.to_time.iso8601) unless blog("notes").articles.empty?
  xml.author { xml.name "Robert Beekman" }

  blog("notes").articles[0..100].each do |article|
    xml.entry do
      xml.title article.title
      xml.link "rel" => "alternate", "href" => URI.join(site_url, article.url)
      xml.id URI.join(site_url, article.url)
      xml.published article.date.to_time.iso8601
      xml.updated File.mtime(article.source_file).iso8601
      xml.author { xml.name "Article Author" }
      # xml.summary article.summary, "type" => "html"
      xml.content article.body, "type" => "html"
    end
  end
end
