require "jekyll"
require_relative "../helpers/flags"

module PupTags
    class TagPage < Jekyll::PageWithoutAFile
        def initialize(site, tag, slug, entries, count)
            @site = site
            @base = site.source
            @dir = File.join("tags", slug)
            @name = "index.html"
            
            process(@name)
            self.data = {
                "layout" => "metalist",
                "title" => "Entries Tagged \"#{tag}\"",
                "tag" => tag,
                "slug" => slug,
                "entries" => entries.sort_by { |d| d.data["date"] || Time.at(0) }.reverse,
                "count" => count,
                "permalink" => "/journal/tags/#{slug}"
            }
        end
    end

    class Generator < Jekyll::Generator
        safe true
        priority :low
        
        def generate(site)
            journal_entries = site.collections["journal"]
            return unless journal_entries

            docs = journal_entries.docs.reject { |d| FrontMatterFlags.truthy?(d.data["private"]) }
            
            # Collect tags from the journal collection only
            tag_map = Hash.new { |h, k| h[k] = [] }
            docs.each do |doc|
                (doc.data["tags"] || []).each { |t| tag_map[t] << doc }  
            end

            tag_map.each do |tag, docs|
                slug = Jekyll::Utils.slugify(tag, mode: "raw")

                Jekyll::logger.info "Generating tag page for #{tag} (#{docs.size} entries)"
                site.pages << TagPage.new(site, tag, slug, docs, docs.size)
            end

            # A tag index page: /journal/tags
            index = Jekyll::PageWithoutAFile.new(site, site.source, "tags", "index.html")
            index.data = {
                "layout" => "alphabet_list",
                "title" => "All Tags",
                "items" => tag_map.keys.sort.map { |t|
                    {
                        "name" => t,
                        "label" => "#" + t,
                        "slug" => "tags/" + Jekyll::Utils.slugify(t, mode: "raw"),
                        "count" => tag_map[t].size,
                        "color" => "primary"
                    }
                },
                "permalink" => "/journal/tags/"
            }
            
            Jekyll::logger.info "Generating tag index with #{tag_map.keys.size} tags"
            site.pages << index
        end
    end
end