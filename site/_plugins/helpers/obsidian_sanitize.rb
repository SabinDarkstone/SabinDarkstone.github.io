module Jekyll
    module ObsidianFilters
        def obsidian_clean(input)
            t = input.to_s.dup

            # Remove full callout blocks that were blockquoted originally:
            #    > [!TYPE][+|-mod]? Title
            #    > subsequent '>' lines...
            t.gsub!(/(^[ \t]*>.*\[\![A-Za-z0-9_-]+(?:[+-][A-Za-z0-9_-]+)?\].*\n(?:^[ \t]*>.*\n)*)/m, " ")

            # Remove bare callout lines that survived without '>'
            #    [!TYPE][+|-mod]? Title ...  (eat the whole line)
            t.gsub!(/^[ \t]*\[\![A-Za-z0-9_-]+(?:[+-][A-Za-z0-9_-]+)?\][^\n]*\n?/m, " ")

            # If any lone markers slipped into the middle of a line, drop just the marker
            t.gsub!(/\[\![A-Za-z0-9_-]+(?:[+-][A-Za-z0-9_-]+)?\]/, " ")

            # Remove remaining blockquote markers (plain > quotes)
            t.gsub!(/^[ \t]*> ?/m, "")

            # Remove embeds and wiki links
            #    ![[file.png]]  => ""
            t.gsub!(/!\[\[[^\]]+\]\]/, " ")
            #    [[Page|Alias]] => "Alias"
            t.gsub!(/\[\[([^\]|]+)\|([^\]]+)\]\]/, '\2')
            #    [[Page]]       => "Page"
            t.gsub!(/\[\[([^\]]+)\]\]/, '\1')

            # Remove images/links markdown (![](), []())
            t.gsub!(/!\[[^\]]*\]\([^)]+\)/, " ")
            t.gsub!(/\[[^\]]*\]\([^)]+\)/, ' ')

            # Footnotes
            t.gsub!(/\[\^[^\]]+\]/, " ")            # inline refs
            t.gsub!(/^\[\^[^\]]+\]:.*$/m, " ")      # definitions

            # Tasks / checkboxes: "- [ ]", "- [x]", "- [-]"
            t.gsub!(/- \[(?: |x|-)\] /i, "- ")

            # Tags like #tag/subtag
            t.gsub!(/(^|\s)#[\w\/-]+/, ' ')

            # Inline code
            t.gsub!(/`[^`]+`/, " ")
            
            # Collapse whitespace
            t.gsub!(/\s+/, " ")
            t.strip
        end
    end
end

Liquid::Template.register_filter(Jekyll::ObsidianFilters)