module RubyNative
  class GroupingExpression
  
    def initialize(expressions)
      @expressions = expressions
    end

    def to_s
      @expressions.join(', ')
    end

  end
end
