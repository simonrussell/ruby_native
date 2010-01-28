module RubyNative
  class ReturnStatement
    
    def initialize(expression)
      @expression = expression
    end

    def to_s
      "result = #{@expression};\ngoto exit;\n"
    end

  end
end
