module RubyNative
  class StatementExpression < Expression
    
    def initialize(statement)
      @statement = statement
    end

    # TODO gcc only!
    def to_s
      "({\n#{@statement}})"
    end

  end
end
