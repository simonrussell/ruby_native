module RubyNative
  class ScopedBlockToplevel < Toplevel

    def initialize(name, arg_scopers, body_expression)
      raise "body must be expression (is #{body_expression.class})" unless body_expression.kind_of?(Expression)

      @name = name
      @arg_scopers = arg_scopers
      @body = body_expression
    end

    def to_s
<<EOS
static VALUE #{@name}(VALUE arg, VALUE outer_scope) 
{
  DECLARE_NODE;
  VALUE result, self = _local_self(outer_scope);
  VALUE scope = _local_alloc(outer_scope, self);
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
