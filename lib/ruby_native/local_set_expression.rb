module RubyNative
  class LocalSetExpression < Expression
    
    def initialize(id, value_expression)
      @id = id
      @value = value_expression
    end

    def to_s
      "(*local_#{@id} = #{@value})"
    end

  end
end
