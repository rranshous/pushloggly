require 'json'

class JSONFinder
  def self.find_in string
    pieces = string.dup.split('{')
    -1.downto(-pieces.length) do |i|
      begin
        possible_json_string = pieces[-i..-1].join('{')
        if possible_json_string.nil?
          return nil
        end
        json_data = JSON.parse('{' + possible_json_string)
        return json_data
      rescue JSON::ParserError
        next
      end
    end
    nil
  end
end
