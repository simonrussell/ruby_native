module RubyNative
  class CallExpression < Expression
    
    def initialize(function, *args)
      @function = function
      @args = args.flatten
    end

    def to_s
      "#{@function}(#{@args.join(', ')})"
    end

  end
end
