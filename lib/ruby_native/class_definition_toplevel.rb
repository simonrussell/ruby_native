module RubyNative
  class ClassDefinitionToplevel < Toplevel

    def initialize(name, body_expression)
      @body = body_expression
    end

    def to_s
      "static VALUE #{@name}(VALUE self) {\n  #{@body};\nreturn Qnil;\n}\n"      
    end

  end
end
