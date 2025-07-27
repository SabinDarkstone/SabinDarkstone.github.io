# site/_plugins/obsidian_wikilinks.rb
Jekyll::Hooks.register [:pages, :documents], :pre_render do |doc, payload|
  # only process Markdown files
  next unless doc.extname.match?(/\.md|\.markdown$/)

  baseurl = doc.site.config["baseurl"] || ""
  journal = doc.site.collections["journal"] || []

  doc.content = doc.content.gsub(/\[\[([^\|\]]+)\|?([^\]]*)\]\]/) do
    file  = Regexp.last_match(1).strip
    text  = Regexp.last_match(2).strip
    label = text.empty? ? file : text

    # try to find the matching journal doc to get its URL
    target = journal.docs.find { |d| d.data["basename"] == file || d.basename_without_ext == file }
    href   = target ? target.url : "#{baseurl}/Journal/#{file}.html"

    # emit a normal Markdown link, which Jekyll/Kramdown will turn into <a>
    "[#{label}](#{href})"
  end
end
