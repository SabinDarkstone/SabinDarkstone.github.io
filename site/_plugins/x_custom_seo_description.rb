# site/_plugins/custom_seo_description.rb
Jekyll::Hooks.register [:pages, :documents], :pre_render do |doc, payload|
  next unless doc.output_ext == ".html"

  # build the bits you want
  rt   = doc.data["reading_time"]
  tags = Array(doc.data["tags"]).join(", ")
  excerpt = doc.data["description"] || doc.data["excerpt"] || ""
  # compose a single string
  custom = []
  custom << "#{rt} min read. • "   if rt
  custom << "Tags: #{tags}. • "    unless tags.empty?
  custom << excerpt
  # overwrite page.description so jekyll-seo-tag picks it up
  doc.data["description"] = custom.join(" ")
end
