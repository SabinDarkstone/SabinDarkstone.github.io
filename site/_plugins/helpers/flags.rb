module FrontMatterFlags
    def self.truthy?(val)
        val == true || (val.is_a?(String) && val.strip.downcase == "true")  
    end
end