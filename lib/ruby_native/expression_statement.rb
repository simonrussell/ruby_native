module RubyNative
  class ExpressionStatement
    
    def initialize(expression)
      @expression = expression
    end

    def to_s
      "#{@expression};\n"
    end

  end
end
