module RubyNative
  class ScopeExpression < Expression
    attr_reader :body, :args

    def initialize(body, args = [], args_scopers = nil)
      # TODO handle parents
      @body = body
      @args = args
      @args_scopers = args_scopers

      raise "you must provide args_scopers if you provide args" if !args.empty? && args_scopers.nil?
    end

    def to_s
      "({\n  VALUE scope = _local_alloc(Qnil, self);\n#{@args_scopers};\n#{@body};\n})"
    end

  end
end
