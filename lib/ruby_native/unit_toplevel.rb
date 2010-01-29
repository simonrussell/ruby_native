module RubyNative
  class UnitToplevel < Toplevel

    def initialize
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

    def symbol(name)
      @symbols[name.to_s] ||= symbol_id!
    end

    def method_definition(args, body_expression)
      named_method_definition("rn_method_#{block_id!}", args, body_expression)
    end

    def named_method_definition(name, args, body_expression)
      compiler = ExpressionCompiler.new(self)
      body = compiler.compile(body_expression)

      args_scopers = compiler.compile(
        s(:block, 
          *args.map { |a| s(:lasgn, a, s(:c_literal, a.to_s)) }
        )
      )

      @blocks << MethodDefinitionToplevel.new(name, args, args_scopers, compiler.locals_used, body)
      name
    end

    def class_definition(body)
      name = "rn_class_#{block_id!}"
      compiler = ExpressionCompiler.new(self)
      compiled_body = compiler.compile(body)

      @blocks << ClassDefinitionToplevel.new(name, compiler.locals_used, compiled_body)
      name
    end

    def block(args, body, scoped)
      name = "rn_block_#{block_id!}"
      compiler = ExpressionCompiler.new(self)
      
      if args.nil?
        arg_scopers = compiler.compile_nil
      elsif args.sexp_type == :lasgn
        arg_scopers = compiler.compile_lasgn(args.sexp_body.first, Sexp.new(:c_literal, 'arg'))
      elsif args.sexp_type == :masgn
        arg_scopers = compiler.masgn_assigns(args.sexp_body.first.sexp_body, 'arg')
      else
        raise "don't know how to use #{args} for arguments to block"
      end

      compiled_body = compiler.compile(body)

      @blocks << (scoped ? ScopedBlockToplevel : BlockToplevel).new(name, arg_scopers, compiler.locals_used, compiled_body)
      name
    end

    def iter(body)
      name = "rn_iter_#{block_id!}"
      compiler = ExpressionCompiler.new(self)
      compiled_body = compiler.compile(body)

      @blocks << IterToplevel.new(name, compiler.locals_used, compiled_body)
      name
    end

    def comment(s)
      @blocks << "/*\n#{s.gsub('*/', '* /')}\n*/\n"           # just in case
    end

    def to_s
      setup_symbols_code + @blocks.join("\n")
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

    private

    def setup_symbols_code
      return '' if @symbols.empty?

      "ID *_symbols;\n" +
      "static void setup_symbols(void) {\n  _symbols = malloc(sizeof(ID) * #{@symbols.values.max + 1});\n#{
        @symbols.map do |name, key|
          "  _symbols[#{key}] = rb_intern(#{name.inspect});"
        end.join("\n")
      }\n}\n\n"
    end
  end
end
