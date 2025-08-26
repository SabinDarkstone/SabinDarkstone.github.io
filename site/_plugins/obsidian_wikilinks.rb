module ObsidianWikilinks
    def self.pre_render(doc)
        # Ignore any non-html files and empty files
        return unless doc.output_ext == ".html" && doc.content
        
        base_url = doc.site.config["baseurl"] || ""
        journal = doc.site.collections["journal"] || []

        doc.content = doc.content.gsub(/\[\[([^\|\]]+)\|?([^\]]*)\]\]/) do
            file = Regexp.last_match(1).strip
            text = Regexp.last_match(2).strip
            label = text.empty? ? file : text
            
            target = journal.docs.find { |d| d.data["basename"] == file || d.basename_without_ext == file }
            href = target ? target.url : "#{base_url}/Journal/${file}.html"

            Jekyll::logger.info "Converting wikilink [[#{file}|#{text}]] to markdown link [#{label}](#{href})"

            "[#{label}](#{href})"
        end
    end  
end