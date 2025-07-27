# site/_plugins/spotify_links.rb
require "dotenv"
Dotenv.load(File.expand_path("../.env", __dir__))

require "rspotify"

# If you’re using jekyll-dotenv, your ENV vars will already be loaded.
# Otherwise uncomment the next two lines to load a local .env:
# require "dotenv"
# Dotenv.load(File.expand_path("../.env", __dir__))

module Jekyll
  class SpotifyLinksTag < Liquid::Tag
    def initialize(tag_name, text, tokens)
      super
      # split on whitespace so you can pass multiple URLs
      @urls = text.strip.split(/\s+/)
    end

    def render(context)
      # authenticate once per render
      RSpotify.authenticate(ENV["SPOTIFY_CLIENT_ID"], ENV["SPOTIFY_CLIENT_SECRET"])

      # build an <li><a>… entry for each URL
      items = @urls.map do |url|
        # extract the track ID
        id = url[%r{track/([A-Za-z0-9]+)}, 1]
        next unless id
        track = RSpotify::Track.find(id)
        title  = track.name
        artist = track.artists.map(&:name).join(", ")
        %(<li><a href="#{url}" target="_blank">#{title} – #{artist}</a></li>)
      end.compact

      # wrap in a <ul> if you passed more than one, or just join
      items.size > 1 ? "<ul>\n#{items.join("\n")}\n</ul>" : items.first.to_s
    rescue => e
      # fail gracefully
      "<p class=\"text-danger\">Error fetching Spotify info: #{e.message}</p>"
    end
  end
end

Liquid::Template.register_tag("spotify_links", Jekyll::SpotifyLinksTag)
