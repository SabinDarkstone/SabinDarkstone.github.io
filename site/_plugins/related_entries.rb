require "set"

module RelatedEntries
    class Generator < Jekyll::Generator
        safe true
        priority :low

        STOP_WORDS = %w[a an the and or but for nor so yet to of in an at by be is it this that].to_set

        def generate(site)
            docs = site.collections["journal"]&.docs || []
            docs = docs.select { |d| d.data["status"] == "published" && d.data["private"] != true }

            docs.each do |doc|
                doc.data["related_entries"] = related_for(doc, docs)
            end
        end

        private

        def related_for(doc, docs, limit = 5)
            docs.reject { |other| other == doc }.map do |other|
                [other, score(doc, other)]
            end.select { |_, score| score.positive? }
                .sort_by { |_, score| -score }
                .first(limit)
                .map(&:first)
        end

        def score(a, b)
            tags_a = a.data["tags"] || []
            tags_b = b.data["tags"] || []
            tag_score = (tags_a & tags_b).length * 1.25

            content_score = jaccard(words(a), words(b))

            output = a.data["title"] + " <-> " + b.data["title"] + ": " + tag_score.to_s + " + " + content_score.to_s + " = " + (tag_score + content_score).to_s
            puts output

            tag_score + content_score
        rescue => e
            puts "Error scoring #{a.data['title']} and #{b.data['title']}: #{e}"
            0.0
        end

        def jaccard(words_a, words_b)
            union = words_a | words_b
            return 0.0 if union.empty?

            intersection = words_a & words_b
            intersection.length.to_f / union.length.to_f
        end

        def words(doc)
            @word_cache ||= {}
            @word_cache[doc.relative_path] ||= begin
                doc.content.downcase.scan(/\b[a-z]{3,}\b/)
                    .reject { |w| STOP_WORDS.include?(w) }
                    .to_set
            end
        end
    end
end