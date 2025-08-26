module JournalUuidPermalink
    class Generator < Jekyll::Generator
        priority :highest
        
        def generate(site)
            collection = site.collections['journal']
            return unless collection
            
            collection.docs.each do |doc|
                uuid = doc.data['uuid']
                next unless uuid && !uuid.empty?

                url = "/journal/#{uuid}.html"

                Jekyll::logger.info "Setting permalink for #{doc.relative_path} to #{url}"

                doc.data['permalink'] = url
                doc.instance_variable_set(:@url, url)
            end
        end
    end
end