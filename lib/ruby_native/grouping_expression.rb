module RubyNative
  class GroupingExpression
  
    def initialize(*expressions)
      @expressions = expressions.flatten
    end

    def to_s
      "(\n#{@expressions.join(",\n")}\n)"
    end

  end
end
