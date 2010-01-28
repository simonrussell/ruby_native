module RubyNative
  class MethodDefinitionToplevel < Toplevel

    def initialize(name, args, args_scopers, body_expression)
      raise "body must be expression (is #{body_expression.class})" unless body_expression.kind_of?(Expression)

      @name = name
      @body = body_expression
      @args = args
      @args_scopers = args_scopers
    end

    def to_s
      arg_list = (['self'] + @args).map do |a|
        "VALUE #{a}"
      end

      "static VALUE #{@name}(#{arg_list.join(', ')}) {\n  VALUE scope = _local_alloc(Qnil, self);\n  #{@args_scopers};\n  return #{@body};\n}\n"
    end

  end
end
