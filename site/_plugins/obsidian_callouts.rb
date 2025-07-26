# site/_plugins/obsidian_callouts.rb
require "nokogiri"

Jekyll::Hooks.register [:documents, :pages], :post_render do |doc|
  next unless doc.output_ext == ".html"

  # Wrap Obsidian callout blockquotes in a <div class="callout …">
  html = doc.output
  html.gsub!(%r{<blockquote>(.*?)</blockquote>}m) do |blk|
    inner = $1

    # Does the first <p> start with [!TYPE] ?
    if inner =~ /^\s*<p>\[!(\w+)\]\s*(.*?)<\/p>/m
      type, title = $1.downcase, $2.strip
      # Remove that first paragraph
      body = inner.sub(%r{^\s*<p>\[!\w+\].*?<\/p>}m, "")
      <<~HTML
        <div class="callout callout-#{type}">
          <div class="callout-title">#{title}</div>
          <div class="callout-body">#{body}</div>
        </div>
      HTML
    else
      blk
    end
  end

  doc.output = html
end
