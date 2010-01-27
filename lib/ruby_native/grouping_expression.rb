module RubyNative
  class GroupingExpression
  
    def initialize(*expressions)
      @expressions = expressions.flatten
    end

    def to_s
      @expressions.join(",\n")
    end

  end
end
