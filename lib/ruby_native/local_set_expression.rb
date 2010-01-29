module RubyNative
  class LocalSetExpression < Expression
    
    def initialize(id, name, value_expression)
      @id = id
      @name = name
      @value = value_expression
    end

    def to_s
      if @name =~ /^!/
        "(local_#{@id} = #{@value})"
      else
        "(*local_#{@id} = #{@value})"
      end
    end

  end
end
