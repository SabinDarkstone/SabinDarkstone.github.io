# site/_plugins/obsidian_callouts.rb
require "nokogiri"
require "securerandom"

ICON_MAP = {
    "note" => "bi-journal-text",
    "info" => "bi-info-circle",
    "tip" => "bi-lightbulb",
    "todo" => "bi-check2-square",
    "success" => "bi-check-circle",
    "question" => "bi-question-circle",
    "warning" => "bi-exclamation-triangle",
    "danger" => "bi-x-octagon",
    "bug" => "bi-bug",
    "example" => "bi-braces",
    "quote" => "bi-quote",
    "abstract" => "bi-layers",
    "failure" => "bi-x-circle",
    "caution" => "bi-shield-exclamation",
    "important" => "bi-exclamation-circle"
}

Jekyll::Hooks.register [:documents, :pages], :post_render do |doc|
    next unless doc.output_ext == ".html"

    frag = Nokogiri::HTML::DocumentFragment.parse(doc.output)

    frag.css("blockquote").each do |bq|
    html = bq.inner_html

    # match [!COLLAPSE] Title on first line
    if html =~ /^\s*<p>\[!COLLAPSE\]\s*(.*?)<\/p>/m
        title     = $1.strip
        body_html = html.sub(%r{^\s*<p>\[!COLLAPSE\].*?</p>}m, "")

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
            <div id="#{cid}" class="collapse callout callout-#collapse">
            <div class="callout-body">
                #{body_html}
            </div>
            </div>
        </div>
        HTML

        bq.replace(new_node)
        
    # Matches: [!TYPE] Optional Title
        elsif html =~ /^\s*<p>\[!(\w+)\]\s*(.*?)<\/p>/m
        raw_type = $1
        type = raw_type.downcase
        title = ($2 || "").strip
        body_html = html.sub(%r{^\s*<p>\[!\w+\].*?</p>}m, "")

        if type == "collapse"
            cid = "callout-#{SecureRandom.hex(4)}"
            title = (title.empty? ? "Details" : title)

            new_node = Nokogiri::HTML::DocumentFragment.parse <<~HTML
                <div class="callout callout-collapse mb-3">
                <button
                    class="callout-title btn-unstyled d-flex align-items-center w-100"
                    type="button"
                    data-bs-toggle="collapse"
                    data-bs-target="##{cid}"
                    aria-expanded="false"
                    aria-controls="#{cid}">
                    <i class="bi bi-chevron-right callout-caret me-2"></i>
                    <span class="callout-title-text">#{title}</span>
                </button>
                <div id="#{cid}" class="collapse">
                    <div class="callout-content">
                    #{body_html}
                    </div>
                </div>
                </div>
            HTML

            bq.replace(new_node)
        else
            icon = ICON_MAP[type] || "bi-info-circle"
            # If no explicit title given, use a nice default of the type
            display_title = title.empty? ? type.capitalize : title

            new_node = Nokogiri::HTML::DocumentFragment.parse <<~HTML
                <div class="callout callout-#{type} mb-3">
                <div class="callout-title d-flex align-items-center">
                    <i class="bi #{icon} me-2"></i>
                    <span class="callout-title-text">#{display_title}</span>
                </div>
                <div class="callout-content">
                    #{body_html}
                </div>
                </div>
            HTML

            bq.replace(new_node)
        end
    end
    end

    doc.output = frag.to_html
end
