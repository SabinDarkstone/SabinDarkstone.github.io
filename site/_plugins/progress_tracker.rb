require "date"
require_relative "helpers/formatting"

module ProgressTracker
    class Generator < Jekyll::Generator
        safe true
        priority :low

        def generate(site)
            goal = site.config.dig("progress_tracker", "monthly_goal") || 0
            today = site.time.to_date

            entries = site.collections["journal"].docs.select do |doc|
                doc.data["status"] == "published" &&
                doc.data["private"] != true &&
                doc.date.to_date <= today
            end

            first_day = Date.new(today.year, today.month, 1)
            monthly_entries = entries.select { |entry| entry.date.to_date >= first_day }
            entries_this_month = monthly_entries.length

            words_this_month = monthly_entries.sum do |entry|
                text = Formatting.strip_markdown(entry.content)
                text.split(/\s+/).size
            end

            progress_pct = goal.positive? ? (entries_this_month.to_f / goal * 100).round(2) : 0

            dates = entries.map { |entry| entry.date.to_date }.uniq
            streak = 0
            current = today
            while dates.include?(current)
                streak += 1
                current -= 1  
            end

            # Sparklines doesn't look so great, so it's commented out for now
            # last_30_days = []
            # (0..29).each do |i|
            #     day = today - i
            #     last_30_days << entries.count { |entry| entry.date.to_date == day }  
            # end

            # max = last_30_days.max
            # max = 1 if max.zero?
            # spark_points = last_30_days.each_with_index.map do |count, idx|
            #     x = (idx.to_f / (last_30_days.length - 1)) * 100
            #     y = 20 - (count.to_f / max) * 20
            #     format('%.2f,%.2f', x, y)
            # end.join(" ")

            site.config["progress"] = {
                "entries_this_month" => entries_this_month,
                "monthly_goal" => goal,
                "progress_pct" => progress_pct,
                "streak" => streak,
                "words_this_month" => Formatting.format_number_with_commas(words_this_month),
                # "sparkline_points" => spark_points
            }
        end
    end
end