require "jekyll"
require "date"
require_relative "../helpers/flags"

module PupArchives
    class ArchivePage < Jekyll::PageWithoutAFile
        def initialize(site, dir, title, entries, permalink, year, month)
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
                "year" => year,
                "month" => month
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
                year_dir = File.join("journal", year)
                year_title = "Entries from #{year}"
                year_permalink = "/journal/#{year}/"
                Jekyll::logger.info "Generating archive page for #{year_title} with #{year_docs.length} entries"
                site.pages << ArchivePage.new(site, year_dir, year_title, year_docs, year_permalink, year, nil)
                
                year_docs.group_by { |d| d.date.strftime("%m") }.each do |month, month_docs|
                    month_name = Date::MONTHNAMES[month.to_i]
                    month_dir = File.join("journal", year, month)
                    month_title = "#{month_name} #{year} Entries"
                    month_permalink = "/journal/#{year}/#{month}/"
                    Jekyll::logger.info "Generating archive page for #{month_title} with #{month_docs.length} entries"
                    site.pages << ArchivePage.new(site, month_dir, month_title, month_docs, month_permalink, year, month)  
                end
            end
        end
    end
end