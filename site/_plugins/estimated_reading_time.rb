Jekyll::Hooks.register [:pages, :documents], :pre_render do |doc|
    next unless doc.output_ext == ".html" and doc.content

    # Rough words-per-minute; tweak if you like
    wpm = 200

    # Strip Markdown code fences and liquid tags
    text = doc.content
                .gsub(/```.+?```/m, "")       # remove fenced code
                .gsub(/\{%\s*.+?\s*%\}/m, "") # remove liquid tags

    # Count words
    words = text.split(/\s+/).size
    minutes = (words.to_f / wpm).ceil

    # Store in page data for use in templates
    doc.data["reading_time"] = minutes      
end
