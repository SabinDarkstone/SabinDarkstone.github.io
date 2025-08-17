require_relative "helpers/flags"

module PrivacyGuards
    def self.pre_render(doc)
        # Document must be part of the journal collection
        return unless doc.respond_to?(:collection) && doc.collection && doc.collection.label == "journal"

        # Apply privacy guard actions to only private documents
        is_private = FrontMatterFlags.truthy?(doc.data["private"])
        return unless is_private

        # Set data on the document
        doc.data["sitemap"] = false
        doc.data["robots"] = "noindex,nofollow"
        doc.data["search_exclude"] = true
        doc.data["feed"] = false
    end  
end