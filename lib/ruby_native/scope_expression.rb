module RubyNative
  class ScopeExpression < Expression
    attr_reader :body, :args

    def initialize(body, args = [])
      # TODO handle parents
      @body = body
      @args = args
    end

    def to_s
      arg_setup = (['self'] + @args).map do |a|
        ExpressionStatement.new(CallExpression.new('_local_set', 'scope', CallExpression.new('rb_intern', a.to_s.inspect), a))
      end.join('')

      "({\n  VALUE scope = _local_alloc();\n#{arg_setup}#{@body};\n})"
    end

  end
end
