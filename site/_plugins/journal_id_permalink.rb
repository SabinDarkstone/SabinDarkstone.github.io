module JournalIdPermalink
    def self.pre_render(doc)
        return unless doc.respond_to?(:collection) && doc.collection && doc.collection.label == 'journal'

        id = doc.data['id']
        return if id.nil? || id.empty?

        doc.data['permalink'] = "/journal/#{id}.html"
    end
end