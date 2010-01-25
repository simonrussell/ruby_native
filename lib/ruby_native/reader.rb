module RubyNative

  class Reader
  
    def self.from_string(s)
      RubyParser.new.parse(s)
    end

  end

end
