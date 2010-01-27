module RubyNative
  class ScopeExpression < Expression
    
    def initialize(body)
      # TODO handle parents
      @body = body
    end

    def to_s
      "({\n  VALUE scope = rb_hash_new();\n#{@body};\n})"
    end

  end
end
