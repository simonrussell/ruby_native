module RubyNative
  class MethodDefinitionToplevel < Toplevel

    def initialize(name, args, args_scopers, locals_used, body_expression)
      raise "body must be expression (is #{body_expression.class})" unless body_expression.kind_of?(Expression)

      @name = name
      @body = body_expression
      @args = args
      @args_scopers = args_scopers
      @locals_used = locals_used
    end

    def to_s
      arg_list = (['self'] + @args).map do |a|
        "VALUE #{a}"
      end

<<EOS
static VALUE #{@name}(#{arg_list.join(', ')}) 
{
  DECLARE_NODE;
  VALUE result, scope = _local_alloc(Qnil, self);
  #{locals_decl(@locals_used)}
  SHUFFLE_NODE(__FILE__, __LINE__);
  #{@args_scopers};
  result = #{@body};
exit:
  DESHUFFLE_NODE;
  return result;
}
EOS
    end

  end
end
