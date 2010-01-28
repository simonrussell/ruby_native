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

    def block(name, args, body_expression)
      body = compile(body_expression)

      args_scopers = compile(
        s(:block, 
          s(:lasgn, :self, s(:c_literal, 'self')),
          *args.map { |a| s(:lasgn, a, s(:c_literal, a.to_s)) }
        )
      )

      if body.is_a?(ScopeExpression)      # inject it in
        body = ScopeExpression.new(body.body, args, args_scopers)
      else
        body = ScopeExpression.new(body, args, args_scopers)
      end

      @blocks << FunctionToplevel.new(name, body)
      name
    end

    def anonymous_block(args, sexp)
      block("rn_anon_#{block_id!}", args, sexp)
    end

    def class_definition(body)
      name = "rn_class_#{block_id!}"
      @blocks << ClassDefinitionToplevel.new(name, compile(body))
      name
    end

    def to_s
      "ID *_symbols;\n" +
      "static void setup_symbols(void) {\n  _symbols = malloc(sizeof(ID) * #{@symbols.values.max + 1});\n#{
        @symbols.map do |name, key|
          "  _symbols[#{key}] = rb_intern(#{name.inspect});"
        end.join("\n")
      }\n}\n\n" + @blocks.join("\n")
    end

    def compile__intern(sym)
      sym = sym.to_s
  
      # the ID of some one-character symbols is the ASCII value of the character
      if sym.length == 1 && "+-/*<>=".include?(sym)
        SimpleExpression.new("'#{sym}'")
      else
#        CallExpression.new('rb_intern', symbol.inspect)
        CallExpression.new('SYM', symbol(sym), sym.inspect)
      end
    end

  end
end
