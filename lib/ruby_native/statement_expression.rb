module RubyNative
  class StatementExpression
    
    def initialize(statement)
      @statement = statement
    end

    # TODO gcc only!
    def to_s
      "({\n#{@statement}\nQnil;\n})"
    end

  end
end
