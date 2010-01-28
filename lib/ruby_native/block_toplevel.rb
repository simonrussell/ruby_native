module RubyNative
  class BlockToplevel < Toplevel

    def initialize(name, body_expression)
      raise "body must be expression (is #{body_expression.class})" unless body_expression.kind_of?(Expression)

      @name = name
      @body = body_expression
    end

    def to_s
      "static VALUE #{@name}(VALUE arg, VALUE scope) {\n  VALUE self = _local_self(scope);\n  return #{@body};\n}\n"
    end

  end
end
