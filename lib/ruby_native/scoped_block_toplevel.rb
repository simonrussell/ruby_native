module RubyNative
  class ScopedBlockToplevel < Toplevel

    def initialize(name, arg_scopers, scope, body_expression)
      raise "body must be expression (is #{body_expression.class})" unless body_expression.kind_of?(Expression)

      @name = name
      @arg_scopers = arg_scopers
      @scope = scope
      @body = body_expression
    end

    def to_s
<<EOS
static VALUE #{@name}(const VALUE arg, const VALUE outer_scope) 
{
  DECLARE_NODE;
  VALUE result;
  const VALUE self = _local_self(outer_scope);
  const VALUE #{@scope.declaration};
  #{locals_decl(@scope)}
  SHUFFLE_NODE(__FILE__, __LINE__),
  #{@arg_scopers};
  result = #{@body};
exit:
  DESHUFFLE_NODE;
  return result;
}
EOS
    end

  end
end
