require "jekyll"
require_relative "../helpers/flags"

module PupMoods
    class MoodPage < Jekyll::PageWithoutAFile
        def initialize(site, mood, slug, entries, count)
            @site = site
            @base = site.source
            @dir = File.join("moods", slug)
            @name = "index.html"
            
            process(@name)
            self.data = {
                "layout" => "metalist",
                "title" => "Entries with Mood \"#{mood}\"",
                "mood" => mood,
                "slug" => slug,
                "entries" => entries.sort_by { |d| d.data["date"] || Time.at(0) }.reverse,
                "count" => count,
                "permalink" => "/journal/moods/#{slug}"
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
            
            # Collect moods from the journal collection only
            mood_map = Hash.new { |h, k| h[k] = [] }
            docs.each do |doc|
                (doc.data["moods"] || []).each { |m| mood_map[m] << doc }  
            end

            mood_map.each do |mood, docs|
                slug = Jekyll::Utils.slugify(mood, mode: "raw")

                Jekyll::logger.info "Generating mood page for #{mood} (#{docs.size} entries)"
                site.pages << MoodPage.new(site, mood, slug, docs, docs.size)
            end

            # A mood index page: /journal/moods
            index = Jekyll::PageWithoutAFile.new(site, site.source, "moods", "index.html")
            index.data = {
                "layout" => "alphabet_list",
                "title" => "All Moods",
                "items" => mood_map.keys.sort.map { |m|
                    {
                        "name" => m,
                        "label" => m,
                        "slug" => "moods/" + Jekyll::Utils.slugify(m, mode: "raw"),
                        "count" => mood_map[m].size,
                        "color" => "info",
                    }
                },
                "permalink" => "/journal/moods/"
            }

            Jekyll::logger.info "Generating mood index with #{mood_map.keys.size} moods"
            site.pages << index
        end
    end
end