require "jekyll"

module PupTags
    class TagPage < Jekyll::PageWithoutAFile
        def initialize(site, tag, slug, entries, count)
            @site = site
            @base = site.source
            @dir = File.join("tags", slug)
            @name = "index.html"
            
            process(@name)
            self.data = {
                "layout" => "tag",
                "title" => "Post Tagged \"#{tag}\"",
                "tag" => tag,
                "slug" => slug,
                "entries" => entries.sort_by { |d| d.data["date"] || Time.at(0) }.reverse,
                "count" => count,
                "permalink" => "/tags/#{slug}"
            }
        end
    end

    class Generator < Jekyll::Generator
        safe true
        priority :low
        
        def generate(site)
            col1 = site.collections["journal"]
            return unless col1
            
            # Collect tags from the journal collection only
            tag_map = Hash.new { |h, k| h[k] = [] }
            col1.docs.each do |doc|
                (doc.data["tags"] || []).each { |t| tag_map[t] << doc }  
            end

            tag_map.each do |tag, docs|
                slug = Jekyll::Utils.slugify(tag, mode: "raw")
                site.pages << TagPage.new(site, tag, slug, docs, docs.size)
            end

            # A tag index page: /tag/
            index = Jekyll::PageWithoutAFile.new(site, site.source, "tags", "index.html")
            index.data = {
                "layout" => "tags",
                "title" => "All Tags",
                "tags" => tag_map.keys.sort.map { |t| { "name" => t, "slug" => Jekyll::Utils.slugify(t, mode: "raw"), "count" => tag_map[t].size } },
                "permalink" => "/tags/"
            }
            site.pages << index
        end
    end
end