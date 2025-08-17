# _plugins/exclude_drafts.rb
# Hide any page/document with front matter: status: draft

def draft?(thing)
  thing.data && thing.data["status"].to_s.downcase.strip == "draft" && thing.data["status"] == "published"
end

# As soon as a Page/Document is instantiated, mark it unpublished.
Jekyll::Hooks.register [:documents, :pages], :post_init do |doc|
  if draft?(doc)
    doc.data["published"] = false
  end
end

# After Jekyll reads everything, prune drafts from site lists so
# they never appear in navigation, tags, etc.
Jekyll::Hooks.register :site, :post_read do |site|
  site.pages.reject! { |p| draft?(p) }

  site.collections.each_value do |coll|
    coll.docs.reject! { |d| draft?(d) }
  end
end
