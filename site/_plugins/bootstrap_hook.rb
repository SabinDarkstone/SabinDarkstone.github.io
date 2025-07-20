# site/_plugins/bootstrap_hook.rb
require 'nokogiri'

Jekyll::Hooks.register :documents, :post_render do |doc|
    next unless doc.output_ext == '.html'

    # Parse the generated HTML
    fragment = Nokogiri::HTML::DocumentFragment.parse(doc.output)

    # Add Bootstrap classes automatically
    fragment.css('table').each    { |t| t['class'] = (t['class'].to_s.split + ['table','table-striped']).uniq.join(' ') }
    fragment.css('img').each      { |i| i['class'] = (i['class'].to_s.split + ['img-fluid']).uniq.join(' ') }
    fragment.css('ul').each       { |u| u['class'] = (u['class'].to_s.split + ['list-unstyled']).uniq.join(' ') }
    fragment.css('ol').each       { |o| o['class'] = (o['class'].to_s.split + ['list-decimal']).uniq.join(' ') }
    fragment.css('pre').each      { |p| p['class'] = (p['class'].to_s.split + ['bg-light','p-3','rounded']).uniq.join(' ') }
    # …add more selectors as needed…

    # Replace the page output
    doc.output = fragment.to_html
end
