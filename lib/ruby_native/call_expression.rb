module RubyNative
  class CallExpression
    
    def initialize(function, *args)
      @function = function
      @args = args.flatten
    end

    def to_s
      "#{@function}(#{@args.join(', ')})"
    end

  end
end
