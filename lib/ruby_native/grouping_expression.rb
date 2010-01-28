module RubyNative
  class GroupingExpression < Expression
  
    def initialize(*expressions)
      @expressions = expressions.flatten
    end

    def to_s
      case @expressions.length
      when 0
        'Qnil'
      when 1
        @expressions.first.to_s
      else
        "(\n#{@expressions.join(",\n")}\n)"
      end
    end

  end
end
