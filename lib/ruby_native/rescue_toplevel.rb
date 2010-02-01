module RubyNative
  class RescueToplevel < Toplevel
    
    def initialize(name, scope, cases)
      @name = name
      @scope = scope
      @cases = cases
    end

    def to_s
<<EOS
static VALUE #{@name}(const VALUE scope, const VALUE exception)
{
  VALUE result;
  const VALUE self = _local_self(scope);
  #{locals_decl(@scope)}
  result = #{@cases};
exit:
  return result;
}
EOS
    end    

  end
end
