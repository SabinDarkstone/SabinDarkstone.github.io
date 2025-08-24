require "jekyll"
require_relative "helpers/flags"

module PupMoods
    class MoodPage < Jekyll::PageWithoutAFile
        def initialize(site, mood, slug, entries, count, color)
            @site = site
            @base = site.source
            @dir = File.join("moods", slug)
            @name = "index.html"
            
            process(@name)
            self.data = {
                "layout" => "mood",
                "title" => "Entries with Mood \"#{mood}\"",
                "mood" => mood,
                "slug" => slug,
                "color" => color,
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
            
            # Build lookup: mood string -> bootstrap color (from _config.yml)
            # Falls back to "primary" if not found.
            mood_color_lookup = Hash.new("primary")
            (site.config["moods"] || {}).each do |color, mood_list|
                Array(mood_list).each { |m| mood_color_lookup[m] = color }
            end
            
            # Collect moods from the journal collection only
            mood_map = Hash.new { |h, k| h[k] = [] }
            docs.each do |doc|
                (doc.data["moods"] || []).each { |m| mood_map[m] << doc }  
            end

            mood_map.each do |mood, docs|
                slug = Jekyll::Utils.slugify(mood, mode: "raw")
                color = mood_color_lookup[mood]
                site.pages << MoodPage.new(site, mood, slug, docs, docs.size, color)
            end

            # A mood index page: /journal/moods
            index = Jekyll::PageWithoutAFile.new(site, site.source, "moods", "index.html")
            index.data = {
                "layout" => "moods",
                "title" => "All Moods",
                "moods" => mood_map.keys.sort.map { |m|
                    {
                        "name" => m,
                        "slug" => Jekyll::Utils.slugify(m, mode: "raw"),
                        "count" => mood_map[m].size,
                        "color" => mood_color_lookup[m]
                    }
                },
                "permalink" => "/journal/moods/"
            }
            site.pages << index
        end
    end
end