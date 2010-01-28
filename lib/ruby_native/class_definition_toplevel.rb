module RubyNative
  class ClassDefinitionToplevel < Toplevel
    attr_reader :name, :body

    def initialize(name, body_expression)
      @name = name
      @body = body_expression
    end

    def to_s
      # we have result var here, but we never actually return it ... lame
      "static VALUE #{@name}(VALUE self) {\n  VALUE result, scope = _local_alloc(Qnil, self);\n  #{@body};\nexit:\n  return Qnil;\n}\n"
    end

  end
end
