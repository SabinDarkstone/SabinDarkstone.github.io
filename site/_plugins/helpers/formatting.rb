module Formatting
    def self.format_number_with_commas(number)
        whole, decimal = number.to_s.split('.')
        whole_with_commas = whole.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
        decimal ? "#{whole_with_commas}.#{decimal}" : whole_with_commas
    end

    def self.strip_markdown(text)
        text.gsub(/```.+?```/m, "")
            .gsub(/\{%\s*.+?\s*%\}/m, "")  
    end
end