module RubyNative
  class SimpleExpression < Expression
    
    def initialize(text)
      @text = text
    end

    def to_s
      @text
    end

  end
end
