module JournalIdPermalink
    def self.pre_render(doc)
        return unless doc.respond_to?(:collection) && doc.collection && doc.collection.label.to_s == 'journal'

        id = (doc.data['id'] || doc.data['ID'] || doc.data[':id']).to_s.strip
        return if id.nil? || id.empty?

        doc.data['permalink'] = "/journal/#{id}.html"
    end
end