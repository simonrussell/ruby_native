module RubyNative
  class UnitToplevel < Toplevel

    def initialize
      @expression_compiler = ExpressionCompiler.new(self)
      @block_id = 0
      @blocks = []
    end

    def block_id!
      @block_id += 1
    end

    def compile(sexp)
      @expression_compiler.compile(sexp)
    end

    def scoped_block(name, sexp)
      block(name, Sexp.new(:scope, sexp))
    end

    def block(name, sexp)
      @blocks << FunctionToplevel.new(name, ReturnStatement.new(compile(sexp)))
      name
    end

    def anonymous_block(sexp)
      block("rn_anon_#{block_id!}", sexp)
    end

    def to_s
      @blocks.join("\n")
    end

  end
end
