require "jekyll"
require "date"
require_relative "helpers/flags"

module PupArchives
    class ArchivePage < Jekyll::PageWithoutAFile
        def initialize(site, dir, title, entries, permalink)
            @site = site
            @base = site.source
            @dir = dir
            @name = "index.html"

            process(@name)
            self.data = {
                "layout" => "archive",
                "title" => title,
                "entries" => entries.sort_by { |d| d.data["date"] || Time.at(0) }.reverse,
                "count" => entries.length,
                "permalink" => permalink,
            }
        end  
    end

    class Generator < Jekyll::Generator
        safe true
        priority :low
        
        def generate(site)
            journal = site.collections["journal"]
            return unless journal
            
            docs = journal.docs.reject { |d| FrontMatterFlags.truthy?(d.data["private"]) }

            docs.group_by { |d| d.date.strftime("%Y") }.each do |year, year_docs|
                year_dir = File.join("Journal", year)
                year_title = "Entries from #{year}"
                year_permalink = "/Journal/#{year}/"
                site.pages << ArchivePage.new(site, year_dir, year_title, year_docs, year_permalink)
                
                year_docs.group_by { |d| d.date.strftime("%m") }.each do |month, month_docs|
                    month_name = Date::MONTHNAMES[month.to_i]
                    month_dir = File.join("Journal", year, month)
                    month_title = "#{month_name} #{year} Entries"
                    month_permalink = "/Journal/#{year}/#{month}/"
                    site.pages << ArchivePage.new(site, month_dir, month_title, month_docs, month_permalink)  
                end
            end
        end
    end
end