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

    def scoped_block(name, args, sexp)
      block(name, args, Sexp.new(:scope, sexp))
    end

    def block(name, args, sexp)
      @blocks << FunctionToplevel.new(name, args, compile(sexp))
      name
    end

    def anonymous_block(args, sexp)
      block("rn_anon_#{block_id!}", args, sexp)
    end

    def to_s
      @blocks.join("\n")
    end

  end
end
