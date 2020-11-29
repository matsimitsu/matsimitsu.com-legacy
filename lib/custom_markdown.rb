# frozen_string_literal: true

# From: https://github.com/hashicorp/middleman-hashicorp/blob/master/lib/middleman-hashicorp/redcarpet.rb

require "middleman-core"
require "middleman-core/renderers/redcarpet"
require "active_support/core_ext/module/attribute_accessors"
require "uri"

class CustomMarkdown < Middleman::Renderers::MiddlemanRedcarpetHTML
  # Make a small wrapper module around a/some Padrino formatting helpers
  # This is not included in the CustomMarkdown class to prevent accidental
  # overriding of methods.
  module FormatHelpersWrapper
    include Padrino::Helpers::FormatHelpers
    module_function :strip_tags
  end

  OPTIONS = {
    :autolink => true,
    :fenced_code_blocks => true,
    :no_intra_emphasis => true,
    :strikethrough => true,
    :tables => true,
    :disable_indented_code_blocks => true
  }.freeze
  SIZES = [360, 720, 1200, 2200].freeze

  # Initialize with correct config.
  # Does not get config from `set :markdown` from `config.rb`
  def initialize(options = {})
    super(options.merge(OPTIONS))
  end

  # Override the default image tag to emit a <figure>
  # with a srcset containing SIZES sizes
  def image(url, flex, type_and_alt = "")

    if !url.end_with?("jpg") && !url.end_with?(".jpeg")
      return super
    end

    type, alt = (type_and_alt.presence || "").split("|")

    srcset = SIZES.map do |size|
      ext = File.extname(url)
      regex = Regexp.new "(-#{SIZES.join("|-")})?#{ext}"
      new_url = url
        .gsub(regex, "-#{size}#{ext}")
      "#{new_url} #{size}w"
    end

    img = %(<figure class="c--markdown__figure" style="flex: #{flex || "1.5"} 1 0%;">
    <a href="#{srcset.last.split(" ").first}" data-action="gallery#onImageClick" data-target="gallery.picture">
        <img
          class="c--markdown__image"
          alt="#{alt || "image"}"
          src="#{srcset[0]}"
          srcset="#{srcset.join(", ")}"
          sizes="360px" />
        </a>
      </figure>)

    if type == "hero"
      %(<div class="c--markdown__hero">#{img}</div>)
    elsif type == "small"
        %(<div class="c--markdown__small">#{img}</div>)
    else
      img
    end
  end

  def preprocess(txt)
    txt.lines.map do |line|
      line.gsub!(/>\[(.+)\]\((\S+)(\s".*")?\)/i) { |_| video($1, $2, $3) }
      line.gsub!(/^\[flight: ([A-Z-]+)\]/i) { |_| @options[:context].flight($1) }
      line.gsub!(/^\[hotel: (.+)\]/i) { |_| @options[:context].hotel($1) }
      line.gsub!(/^\[location: (.+)\]/i) { |_| @options[:context].location($1) }
      line.gsub!(/^\[exif: (.+)\]/i) { |_| @options[:context].exif($1) }
      line
    end.join
  end

  def video(type_and_alt, filename, flex)
    ext = File.extname(filename)
    base_url = filename.gsub(ext, "")
    type, alt = type_and_alt.split("|")
    flex = flex ? flex.tr('"', "").strip : "1.5"

    video = %(<figure class="c--markdown__figure" style="flex: #{flex} 1 0%;">
      <video class="c--markdown__video" alt="#{alt}" width="100%" poster="#{base_url}.jpg" playsinline autoplay muted loop>
        <source src="#{base_url}.mp4" type="video/mp4" />
        <source src="#{base_url}.ogv" type="video/ogg" />
        <source src="#{base_url}.webm" type="video/webm" />
      </video>
    </figure>)

    classes = if type == "hero"
                "c--markdown__hero"
              else
                "c--markdown__figurerow"
              end
    %(<div class="#{classes}">#{video}</div>)
  end

  def paragraph(text)
    if text.strip.start_with?("<div")
      text
    elsif text.start_with?("<figure")
      %(<div class="c--markdown__figurerow">#{text}</div>)
    else
      %(<p>#{text.strip}</p>)
    end
  end
end
