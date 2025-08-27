require "jekyll"

module ObsidianEmbed
	def self.pre_render(doc)
        # Ignore any non-html files and empty files
        return unless doc.output_ext == ".html" && doc.content

        site = doc.site
        baseurl = site.config["baseurl"].to_s
        attach_root = site.config["attachments_dir"] || "assets"

        join_url = ->(*parts) { parts.compact.join("/".gsub(%r{//+}, "/")) }

        doc.content = doc.content.gsub(/!\[\[([^\]\|#]+)(?:#[^\]]*)?(?:\|([^\]]+))?\]\]/) do
            file = Regexp.last_match(1).strip
            opt = Regexp.last_match(2)&.strip

            alt_text = width = height = nil
            if opt
                case opt
                    when /^\s*(\d+)\s*x\s*(\d+)\s*$/i
                        width, height = $1, $2
                    when /^\s*(\d+)\s*$/
                        width = $1
                    else
                        alt_text = opt
                end
            end

            file_url = file.gsub(" ", "%20")

            src = join_url.call(baseurl, attach_root, file_url)

            attrs = []
            attrs << %(src="#{src}")
            attrs << %(alt="#{alt_text}") if alt_text
            attrs << %(width="#{width}") if width
            attrs << %(height="#{height}") if height
            attrs << %(loading="lazy")
            attrs << %(decoding="async")
            attrs << %(class="img-fluid rounded shadow-sm my-3")
            "<img #{attrs.join(' ')} />"
        end
	end
end