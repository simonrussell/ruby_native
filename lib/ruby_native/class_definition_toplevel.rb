module RubyNative
  class ClassDefinitionToplevel < Toplevel
    attr_reader :name, :body

    def initialize(name, body_expression)
      @name = name
      @body = body_expression
    end

    def to_s
      "static VALUE #{@name}(VALUE self) {\n  VALUE scope = _local_alloc(Qnil, self);\n  #{@body};\n  return Qnil;\n}\n"      
    end

  end
end
