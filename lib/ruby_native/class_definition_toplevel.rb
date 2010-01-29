module RubyNative
  class ClassDefinitionToplevel < Toplevel
    attr_reader :name, :body

    def initialize(name, scope, body_expression)
      @name = name
      @body = body_expression
      @scope = scope
    end

    def to_s
      # we have result var here, but we never actually return it ... lame
<<EOS
static VALUE #{@name}(const VALUE self) {
  VALUE result;
  const VALUE #{@scope.declaration};
  #{locals_decl(@scope)}
  #{@body};
exit:
  return Qnil;
}
EOS
    end

  end
end
