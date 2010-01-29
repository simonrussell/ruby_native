module RubyNative
  class IterToplevel < Toplevel

    def initialize(name, locals_used, body_expression)
      raise "body must be expression (is #{body_expression.class})" unless body_expression.kind_of?(Expression)

      @name = name
      @locals_used = locals_used
      @body = body_expression
    end

    def to_s
<<EOS
static VALUE #{@name}(VALUE scope) 
{
  VALUE result, self = _local_self(scope);
  #{locals_decl(@locals_used)}
  result = #{@body};
exit:
  return result;
}
EOS
    end

  end
end
