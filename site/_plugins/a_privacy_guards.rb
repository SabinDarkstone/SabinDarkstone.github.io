Jekyll::Hooks.register [:documents, :pages], :pre_render do |doc|
    next unless doc.respond_to?(:collection) && doc.collection && doc.collection.label == "journal"

    is_private = doc.data["private"] == true || (doc.data["private"].is_a?(String) && doc.data["private"].strip.downcase == "true")
    next unless is_private

    doc.data["sitemap"] = false
    doc.data["robots"] = "noindex,nofollow"
    doc.data["search_exclude"] = true
    doc.data["feed"] = false
end