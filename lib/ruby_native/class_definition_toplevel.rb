module RubyNative
  class ClassDefinitionToplevel < Toplevel
    attr_reader :name, :body

    def initialize(name, locals_used, body_expression)
      @name = name
      @body = body_expression
      @locals_used = locals_used
    end

    def to_s
      # we have result var here, but we never actually return it ... lame
<<EOS
static VALUE #{@name}(VALUE self) {
  VALUE result, scope = _local_alloc(Qnil, self);
  #{locals_decl(@locals_used)}
  #{@body};
exit:
  return Qnil;
}
EOS
    end

  end
end
