require "jekyll"

Jekyll::Hooks.register [:documents, :pages], :pre_render do |doc|
    next unless doc.respond_to?(:content) && doc.content

    site = doc.site
    baseurl = site.config["baseurl"].to_s
    attach_root = site.config["attachments_dir"] || "assets/imgs/attachments"

    join_url = ->(*parts) { parts.compact.join("/").gsub(%r{//+}, "/") }

    doc.content = doc.content.gsub(/!\[\[([^\]\|#]+)(?:#[^\]]*)?(?:\|([^\]]+))?\]\]/) do
		file = Regexp.last_match(1).strip
		opt = Regexp.last_match(2)&.strip

		alt = width = height = nil
		if opt
			case opt
			when /^\s*(\d+)\s*x\s*(\d+)\s*$/i
				width, height = $1, $2
			when /^\s*(\d+)\s*$/
				width = $1
			else
				alt = opt
			end
		end

		file_url = file.gsub(" ", "%20")

		src = join_url.call(baseurl, attach_root, file_url)

		attrs = []
		attrs << %(src="#{src}")
		attrs << %(alt="#{alt}") if alt
		attrs << %(width="#{width}") if width
		attrs << %(height="#{height}") if height
		attrs << %(loading="lazy")
		attrs << %(decoding="async")
		attrs << %(class="img-fluid rounded shadow-sm my-3")
		"<img #{attrs.join(' ')} />"
  	end
end
