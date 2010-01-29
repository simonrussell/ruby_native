module RubyNative
  class LocalSetExpression < Expression
    
    def initialize(variable, value_expression)
      @variable = variable
      @value = value_expression
    end

    def to_s
      "(#{@variable} = #{@value})"
    end

  end
end
