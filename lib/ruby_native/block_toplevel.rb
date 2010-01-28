module RubyNative
  class BlockToplevel < Toplevel

    def initialize(name, arg_scopers, body_expression)
      raise "body must be expression (is #{body_expression.class})" unless body_expression.kind_of?(Expression)

      @name = name
      @arg_scopers = arg_scopers
      @body = body_expression
    end

    def to_s
      "static VALUE #{@name}(VALUE arg, VALUE scope) {\n  VALUE result, self = _local_self(scope);\n  #{@arg_scopers};\n  result = #{@body};\nexit:\n  return result;\n}\n"
    end

  end
end
