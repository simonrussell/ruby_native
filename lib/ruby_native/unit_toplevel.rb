module RubyNative
  class UnitToplevel < Toplevel

    def initialize
      @expression_compiler = ExpressionCompiler.new(self)

      @block_id = 0
      @blocks = []

      @symbol_id = -1
      @symbols = {}
    end

    def block_id!
      @block_id += 1
    end
    
    def symbol_id!
      @symbol_id += 1
    end

    def compile(sexp)
      @expression_compiler.compile(sexp)
    end

    def symbol(name)
      @symbols[name] ||= symbol_id!
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
      "ID *_symbols;\n" +
      "static void setup_symbols(void) {\n  _symbols = malloc(sizeof(ID) * #{@symbols.values.max + 1});\n#{
        @symbols.map do |name, key|
          "  _symbols[#{key}] = rb_intern(#{name.inspect});"
        end.join("\n")
      }\n}\n\n" + @blocks.join("\n")
    end

  end
end
