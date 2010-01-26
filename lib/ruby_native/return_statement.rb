module RubyNative
  class ReturnStatement
    
    def initialize(expression)
      @expression = expression
    end

    def to_s
      "return #{@expression};\n"
    end

  end
end
