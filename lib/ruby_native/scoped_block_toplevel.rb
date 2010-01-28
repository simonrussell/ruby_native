module RubyNative
  class ScopedBlockToplevel < Toplevel

    def initialize(name, arg_scopers, body_expression)
      raise "body must be expression (is #{body_expression.class})" unless body_expression.kind_of?(Expression)

      @name = name
      @arg_scopers = arg_scopers
      @body = body_expression
    end

    def to_s
      "static VALUE #{@name}(VALUE arg, VALUE outer_scope) {\n  VALUE self = _local_self(outer_scope);\n  VALUE scope = _local_alloc(outer_scope, self);\n  #{@arg_scopers};\n  return #{@body};\n}\n"
    end

  end
end
