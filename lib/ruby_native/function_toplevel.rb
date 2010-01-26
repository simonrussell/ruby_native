module RubyNative
  class FunctionToplevel

    def initialize(name, body)
      @name = name
      @body = body
    end

    def to_s
      "VALUE #{@name}(VALUE self) {\n  #{@body}}\n"
    end

  end
end
