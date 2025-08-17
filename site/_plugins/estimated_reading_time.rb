module EstimatedReadingTime
    def self.pre_render(doc)
        # Ignore any non-html files and empty files
        return unless doc.output_ext == ".html" && doc.content

        average_words_per_minute = 200
        
        # Strip markdown code fences and liquid tags
        text = doc.content
            .gsub(/```.+?```/m, "")
            .gsub(/\{%\s*.+?\s*%\}/m, "")
        
        # Count words in the text naively
        words = text.split(/\s+/).size
        minutes = (words.to_f / average_words_per_minute).ceil

        # Store in page data for later use in templates
        doc.data["reading_time"] = minutes
    end  
end