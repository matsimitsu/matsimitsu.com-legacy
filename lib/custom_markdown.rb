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
    type, alt = (type_and_alt.presence || "").split("|")

    srcset = SIZES.map do |size|
      ext = File.extname(url)
      regex = Regexp.new "(-#{SIZES.join("|-")})?#{ext}"
      new_url = url
        .gsub(regex, "-#{size}#{ext}")
      "#{new_url} #{size}w"
    end

    img = %(<figure class="ScaledImage" style="flex: #{flex || "1.5"} 1 0%;">
        <img
          alt="#{alt || "image"}"
          src="#{srcset[0]}"
          srcset="#{srcset.join(", ")}"
          sizes="360px" />
      </figure>)

    return %(<div class="Hero Container full">#{img}</div>) if type == "hero"

    img
  end

  def preprocess(txt)
    txt.lines.map do |line|
      line.gsub(/>\[(.+)\]\((\S+)(\s".*")?\)/i) { |_| video($1, $2, $3) }
      line.gsub(/^\[flight: ([A-Z-]+)\]/i) { |_| flight($1) }
    end.join
  end

  def flight(from_to)
    flight = @options[:context].current_article.data[:flights][from_to]
    return unless flight

    from = flight["from"]
    to = flight["to"]
    duration = Time.at(flight.duration).utc

    %(<div class="Flight Container narrow">
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
          <h3 class="H-Large">#{from.code}</h3>
          <p>#{from.name}</p>
          <small>#{Time.parse(from.time).strftime("%H:%M")}</small>
        </div>
        <div class="duration"><time>#{duration.strftime("%H:%M")}</time></div>
        <div class="to">
          <h3 class="H-Large">#{to.code}</h3>
          <p>#{to.name}</p>
          <small>#{Time.parse(to.time).strftime("%H:%M")}</small>
        </div>
      </div>
    </div>)
  end

  def video(type_and_alt, filename, flex)
    ext = File.extname(filename)
    base_url = filename.gsub(ext, "")
    type, alt = type_and_alt.split("|")
    flex = flex ? flex.tr('"', "").strip : "1.5"

    video = %(<figure class="ScaledImage" style="flex: #{flex} 1 0%;">
      <video alt="#{alt}" width="100%" poster="#{base_url}.jpg" playsinline autoplay muted loop>
        <source src="#{base_url}.mp4" type="video/mp4" />
        <source src="#{base_url}.ogv" type="video/ogg" />
        <source src="#{base_url}.webm" type="video/webm" />
      </video>
    </figure>)

    return %(<div class="Hero Container full">#{video}</div>) if type == "hero"

    video
  end

  def paragraph(text)
    if text.strip.start_with?("<div")
      text
    elsif text.start_with?("<figure")
      %(<div class="PhotoRow Container">#{text}</div>)
    else
      "<p>#{text.strip}</p>"
    end
  end
end
