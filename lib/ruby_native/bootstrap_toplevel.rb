module RubyNative
  class BootstrapToplevel < Toplevel

    def initialize(name, target_name)
      @name = name
      @target = target_name
    end

    def to_s
<<EOS
static VALUE #{@name}(VALUE self, VALUE real_self) 
{
  return #{@target}(real_self);
}
EOS
    end

  end
end
