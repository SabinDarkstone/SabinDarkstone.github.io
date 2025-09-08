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

module ObsidianCalloutAndCollapse
    def self.post_render(doc)
        # Ignore any non-html files
        return unless doc.output_ext == ".html"
        
        frag = Nokogiri::HTML::DocumentFragment.parse(doc.output)

        frag.css("blockquote").each do |blockquote|
            html = blockquote.inner_html.strip

            # Special collapse handle
            if html =~ /^\s*<p>\[!COLLAPSE\]\s*(.*?)<\/p>/m
                title = $1.strip
                blockquote.replace(handle_collapse_with_title(html, title))

            # General callout handling
            elsif html =~ /^\s*<p>\[!(\w+)\]\s*(.*?)<\/p>/m
                type = $1.strip
                title = $2.strip

                if type == "collapse"
                    blockquote.replace(handle_collapse_without_title(html, title))
                else
                    blockquote.replace(handle_callout(html, type, title))
                end

            # General blockquote handling
            else
                cleaned = html.sub(%r{^<p>(.*?)</p>$}m, '\1')
                cleaned = cleaned.gsub(/\n(?!\n)/, "<br>\n")
                blockquote.replace("<blockquote class=\"blockquote\"><p class=\"mb-0\">#{cleaned}</p></blockquote>")
            end
        end

        doc.output = frag.to_html
    end

    private

    def self.handle_collapse_with_title(html, title)
        body_html = html.sub(%r{^\s*<p>\[!COLLAPSE\].*?</p>}m, "")

        callout_id = "callout-#{SecureRandom.hex(4)}"
        
        new_node = Nokogiri::HTML::DocumentFragment.parse <<~HTML
            <div class="mb-2">
                <button
                    class="btn btn-sm btn-primary"
                    type="button"
                    data-bs-toggle="collapse"
                    data-bs-target="##{callout_id}"
                    aria-expanded="false"
                    aria-controls="#{callout_id}">
                    #{title}
                </button>
                <div id="#{callout_id}" class="collapse callout callout-info callout-#collapse mt-2">
                    <div class="callout-content">
                        #{body_html}
                    </div>
                </div>
            </div>
        HTML
        new_node
    end

    def self.handle_collapse_without_title(html, title)
        body_html = html.sub(%r{^\s*<p>\[!\w+\].*?</p>}m, "")
        callout_id = "callout-#{SecureRandom.hex(4)}"
        title = (title.empty? ? "Details" : title)

        new_node = Nokogiri::HTML::DocumentFragment.parse <<~HTML
            <div class="callout callout-info callout-collapse mb-3">
                <button
                    class="callout-title btn-sm btn-unstyled d-flex align-items-center w-100"
                    type="button"
                    data-bs-toggle="collapse"
                    data-bs-target="##{callout_id}"
                    aria-expanded="false"
                    aria-controls="#{callout_id}">
                    <i class="bi bi-chevron-right callout-caret me-2"></i>
                    <span class="callout-title-text">#{title}</span>
                </button>
                <div id="#{callout_id}" class="collapse">
                    <div class="callout-content">
                        #{body_html}
                    </div>
                </div>
            </div>
        HTML
        new_node
    end

    def self.handle_callout(html, raw_type, title)
        type = raw_type.downcase
        body_html = html.sub(%r{^\s*<p>\[!\w+\].*?</p>}m, "")
        icon = ICON_MAP[type] || "bi-info-circle"
        display_title = title.empty? ? type.capitalize : title

        if (body_html.size > 4)
            new_node = Nokogiri::HTML::DocumentFragment.parse <<~HTML
                <div class="callout callout-#{type} mb-3">
                    <div class="callout-title d-flex align-items-center">
                        <i class="bi #{icon} me-2"></i>
                        <span class="callout-title-text">
                            #{display_title}
                        </span>
                    </div>
                    <div class="callout-content">
                        #{body_html}
                    </div>
                </div>
            HTML
        else
            new_node = Nokogiri::HTML::DocumentFragment.parse <<~HTML
                <div class="callout callout-#{type} mb-3">
                    <div class="callout-title d-flex align-items-center">
                        <i class="bi #{icon} me-2"></i>
                        <span class="callout-title-text">
                            #{display_title}
                        </span>
                    </div>
                </div>
            HTML
        end
        
        new_node
    end
end