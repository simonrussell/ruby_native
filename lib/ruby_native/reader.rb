module RubyNative

  class Reader
  
    def self.from_string(s, file = nil)
      parser = RubyParser.new
      parser.parse(s, file || "(rubynative)")
    end

  end

end
