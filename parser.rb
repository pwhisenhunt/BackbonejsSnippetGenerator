# @author Phillip Whisenhunt
# Quick and dirty script to auto generate sublime text 2 backbone.js tab completion snippets

require 'nokogiri'
require 'open-uri'

doc = Nokogiri::HTML(open('http://www.backbonejs.org'))

["View", "Collection", "Model", "Router", "Events", "Sync", "History", "Utility"].each do |type|

    doc.css("[id^=#{type}-]").each do |item|
        # In case the type being passed is event, convert it to object because the 
        # docs have object.function, not event.function
        type = "object" if type.include? "event"
        type.downcase!

        name = item.css("b.header").text
        name = name.split("/")[0] if name.include? "/"
        name.insert(0 ,"b#{type[0]}").strip!

        code = item.css('code').text
        parameter = 1

        # If the code follow *object.function then replace *object with the first paramter
        if code.include? type
            code.sub!(/#{type}/, "${#{parameter}:#{type}}")
            parameter += 1
        end

        if code.include? "("
            code_parts = code.split("(")
            params = code_parts[1]
            new_params = []

            # If there are params, convert them to snippet params
            if(params != ")")

                params.gsub!(/\)/, "").split(",").each do |param|
                    new_params << "${#{parameter}:#{param.strip}}"
                    parameter += 1
                end
            end
            code = code_parts[0] + "(" + new_params.join(", ") + ")"
        end

        # Make sure there's code and that the code isn't underscore helpers
        if code != "" and !code.include? "Underscore"
            file_contents = "<snippet>\n    <content>\n<![CDATA[\n#{code}\n]]>\n    </content>\n    <tabTrigger>#{name}</tabTrigger>\n    <scope>source.js</scope>\n    <description>Backbone.js #{type.slice(0,1).capitalize + type.slice(1..-1)} #{name[2..-1]}</description>\n</snippet>"
            File.open("backbone.#{type}.#{name[2..-1]}.sublime-snippet", 'a+') { |f| f.write(file_contents) }
        end
    end
end