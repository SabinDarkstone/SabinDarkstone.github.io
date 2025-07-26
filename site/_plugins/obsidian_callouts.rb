# site/_plugins/obsidian_callouts.rb
require "nokogiri"
require "securerandom"

Jekyll::Hooks.register [:documents, :pages], :post_render do |doc|
  next unless doc.output_ext == ".html"

  frag = Nokogiri::HTML::DocumentFragment.parse(doc.output)

  # transform each Obsidian callout (<blockquote>[!TYPE] Title …</blockquote>)
  frag.css("blockquote").each do |bq|
    html = bq.inner_html

    # match [!TYPE] Title on first line
    if html =~ /^\s*<p>\[!(\w+)\]\s*(.*?)<\/p>/m
      type, title = $1.downcase, $2.strip
      body_html   = html.sub(%r{^\s*<p>\[!\w+\].*?</p>}m, "")

      # unique ID for collapse
      cid = "callout-#{SecureRandom.hex(4)}"

      # build the new node
      new_node = Nokogiri::HTML::DocumentFragment.parse <<~HTML
        <div class="mb-2">
          <button
            class="btn btn-primary"
            type="button"
            data-bs-toggle="collapse"
            data-bs-target="##{cid}"
            aria-expanded="false"
            aria-controls="#{cid}">
            #{title}
          </button>
          <div id="#{cid}" class="collapse callout callout-#{type}">
            <div class="callout-body">
              #{body_html}
            </div>
          </div>
        </div>
      HTML

      bq.replace(new_node)
    end
  end

  doc.output = frag.to_html
end
