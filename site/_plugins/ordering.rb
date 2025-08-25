require_relative "privacy_guards"
require_relative "estimated_reading_time"
require_relative "obsidian_embed"
require_relative "obsidian_wikilinks"
require_relative "custom_seo_description"
require_relative "obsidian_callout_and_collapse"

PRE_RENDER_PLUGINS = [
    PrivacyGuards,
    EstimatedReadingTime,
    ObsidianEmbed,
    ObsidianWikilinks,
    CustomSeoDescription
]

POST_RENDER_PLUGINS = [
    ObsidianCalloutAndCollapse
]

Jekyll::Hooks.register [:pages, :documents], :pre_render do |doc|
    PRE_RENDER_PLUGINS.each { |plugin| plugin.pre_render(doc) }
end

Jekyll::Hooks.register [:pages, :documents], :post_render do |doc|
    POST_RENDER_PLUGINS.each { |plugin| plugin.post_render(doc) }  
end
