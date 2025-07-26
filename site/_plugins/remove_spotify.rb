# site/_plugins/remove_spotify.rb
Jekyll::Hooks.register [:pages, :documents], :post_render do |doc|
  # only touch HTML pages
  next unless doc.output_ext == ".html"

  # blast away any "On Spotify" in your <a> tags
  doc.output = doc.output.gsub(
    /<a([^>]*)>([^<]*?)On Spotify([^<]*?)<\/a>/,
    '<a\1>\2\3</a>'
  )
end
