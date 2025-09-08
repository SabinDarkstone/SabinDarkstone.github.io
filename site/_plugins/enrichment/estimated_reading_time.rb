require_relative "../helpers/formatting"

module EstimatedReadingTime
    def self.pre_render(doc)
        # Ignore any non-html files and empty files
        return unless doc.output_ext == ".html" && doc.data["layout"] == "journal" && doc.content

        Jekyll::logger.info "Calculating estimated reading time for #{doc.relative_path}"

        average_words_per_minute = 200
        
        # Strip markdown code fences and liquid tags
        text = Formatting.strip_markdown(doc.content)
        
        # Count words in the text naively
        words = text.split(/\s+/).size
        minutes = (words.to_f / average_words_per_minute).ceil

        # Store in page data for later use in templates
        doc.data["reading_time"] = minutes
    end  
end