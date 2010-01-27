module RubyNative
  class ExpressionStatement
    
    def initialize(expression, prefix = nil)
      @expression = expression
      @prefix = prefix
    end

    def to_s
      "#{@prefix}#{' ' if @prefix}#{@expression};\n"
    end

  end
end
