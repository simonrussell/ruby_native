module RubyNative
  class FunctionToplevel

    def initialize(name, body_expression)
      raise "body must be expression" unless body_expression.kind_of?(Expression)

      @name = name
      @body = body_expression
    end

    def to_s
      "static VALUE #{@name}(VALUE self) {\nreturn #{@body};\n}\n"
    end

  end
end
