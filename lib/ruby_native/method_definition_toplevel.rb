module RubyNative
  class MethodDefinitionToplevel < Toplevel

    def initialize(name, args, args_scopers, scope, body_expression)
      raise "body must be expression (is #{body_expression.class})" unless body_expression.kind_of?(Expression)

      @name = name
      @body = body_expression
      @args = args
      @args_scopers = args_scopers
      @scope = scope
    end

    def to_s
      arg_list = (['self'] + @args).map do |a|
        "const VALUE #{a}"
      end

      if @body.to_s == 'Qnil'   # lame
<<EOS
static VALUE #{@name}(#{arg_list.join(', ')}) 
{
  return Qnil;
}
EOS
      else        
<<EOS
static VALUE #{@name}(#{arg_list.join(', ')}) 
{
  DECLARE_NODE;
  VALUE result;
  const VALUE #{@scope.declaration};
  #{locals_decl(@scope)}
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
end
