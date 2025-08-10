# site/_plugins/inject_tags.rb
require "nokogiri"

Jekyll::Hooks.register :documents, :post_render do |doc|
    # only HTML pages with tags
    next unless doc.output_ext == ".html" && doc.data["tags"]

    # parse the rendered output
    frag = Nokogiri::HTML::DocumentFragment.parse(doc.output)

    # build the pills HTML
    tags_html = doc.data["tags"].map do |t|
        %(<span class="badge rounded-pill bg-secondary me-1 mb-1">#{t}</span>)
    end.join
    wrapper = Nokogiri::HTML::DocumentFragment.parse(%(<div class="mb-4">#{tags_html}</div>))

    # find the first <h1> and insert after it (or prepend if no <h1>)
    if h1 = frag.at_css("h1")
        h1.add_next_sibling(wrapper)
    else
        frag.children.first.add_previous_sibling(wrapper)
    end

    # overwrite the page output
    doc.output = frag.to_html
end
