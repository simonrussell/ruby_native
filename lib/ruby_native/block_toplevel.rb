module RubyNative
  class BlockToplevel < Toplevel

    def initialize(name, arg_scopers, locals_used, body_expression)
      raise "body must be expression (is #{body_expression.class})" unless body_expression.kind_of?(Expression)

      @name = name
      @arg_scopers = arg_scopers
      @locals_used = locals_used
      @body = body_expression
    end

    def to_s
<<EOS
static VALUE #{@name}(const VALUE arg, const VALUE scope) 
{
  VALUE result;
  const VALUE self = _local_self(scope);
  #{locals_decl(@locals_used)}
  #{@arg_scopers};
  result = #{@body};
exit:
  return result;
}
EOS
    end

  end
end
