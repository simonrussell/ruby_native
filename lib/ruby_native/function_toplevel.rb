module RubyNative
  class FunctionToplevel

    def initialize(name, body_expression)
      raise "body must be expression" unless body_expression.kind_of?(Expression)

      @name = name
      @body = body_expression
    end

    def to_s
      if @body.is_a?(ScopeExpression)
        arg_list = @body.args.map do |a|
          "VALUE #{a}"
        end
      else
        arg_list = []
      end

      arg_list.unshift('VALUE self')

      "static VALUE #{@name}(#{arg_list.join(', ')}) {\n  return #{@body};\n}\n"
    end

  end
end
