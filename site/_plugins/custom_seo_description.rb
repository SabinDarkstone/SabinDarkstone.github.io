module CustomSeoDescription
    def self.pre_render(doc)
        # Ignore any non-html files
        return unless doc.output_ext == ".html"

        # Extract reading time, tags, and the excerpt
        reading_time = doc.data["reading_time"]
        tag_string = Array(doc.data["tags"]).join(", ")
        excerpt = doc.data["description"] || doc.data["excerpt"] || ""

        # Create a custom SEO description
        custom = []
        custom << "#{reading_time} min read •" if reading_time
        custom << "Tags: #{tag_string} • " if tag_string
        custom << excerpt

        doc.data["description2"] = excerpt.strip
        doc.data["description"] = custom.join(" ").strip
    end
end