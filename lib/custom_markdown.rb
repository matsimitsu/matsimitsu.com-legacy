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
  SIZES = %w(360 720 1200 2200).freeze

  # Initialize with correct config.
  # Does not get config from `set :markdown` from `config.rb`
  def initialize(options = {})
    super(options.merge(OPTIONS))
  end

  def image(url, flex, type_and_alt)
    type, alt = type_and_alt.split("|")

    srcset = SIZES.map do |size|
      ext = File.extname(url)
      "#{url.gsub(ext, "-#{size}#{ext}")} #{size}w"
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

  def paragraph(text)
    if text.start_with?("<div")
      text
    elsif text.start_with?("<figure")
      %(<div class="PhotoRow Container">#{text}</div>)
    else
      "<p>#{text.strip}</p>"
    end
  end
end
