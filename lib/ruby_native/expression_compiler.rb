module RubyNative
  class ExpressionCompiler
    
    def initialize
      @block_id = 0
    end

    def block_id!
      @block_id += 1
    end

    def compile(sexp)
      return compile_nil if sexp.nil?

      sexp = send("transform_#{sexp.sexp_type}", *sexp.sexp_body) while respond_to?("transform_#{sexp.sexp_type}")
      send("compile_#{sexp.sexp_type}", *sexp.sexp_body)
    end

    def compile_c_literal(value)
      SimpleExpression.new(value)
    end

    def compile_nil
      SimpleExpression.new('Qnil')
    end

    def compile_true
      SimpleExpression.new('Qtrue')
    end

    def compile_false
      SimpleExpression.new('Qfalse')
    end

    def compile_self
      SimpleExpression.new('self')
    end

    def compile_block(*expressions)
      GroupingExpression.new(expressions.map { |x| compile(x) })
    end

    def compile_while(test, body, test_before, not_test = false)
      StatementExpression.new(
        WhileStatement.new(
          compile(test),
          ExpressionStatement.new(compile(body)),
          test_before,
          not_test
        )
      )
    end

    def compile_until(test, body, test_before)
      compile_while(test, body, test_before, true)
    end

    def compile_lit(value)
      case value
      when Fixnum
        SimpleExpression.new("LONG2FIX(#{value})")
      when String
        SimpleExpression.new("rb_str_new2(#{value.inspect})")
      when Symbol
        SimpleExpression.new("ID2SYM(#{compile__intern(value)})")
      when Range
        compile__range(s(:lit, value.first), s(:lit, value.last), value.exclude_end?)
      else
        raise "don't know how to compile literal #{value.inspect}"
      end
    end

    alias :compile_str :compile_lit

    def compile_const(name)
      case name
      when :Kernel
        SimpleExpression.new("rb_m#{name}")
      else
        raise "don't know how to compile const #{name}"
      end
    end

    def compile_gvar(name)
      CallExpression.new("rb_gv_get", name.to_s[1..-1].inspect)
    end

    def transform_dstr(first, *part_expressions)
      literals = [format_escape(first)]
      expressions = []
      
      part_expressions.each do |x|
        case x.sexp_type
        when :evstr
          literals << '%s'
          expressions << x.sexp_body.first
        when :str
          literals << format_escape(x.sexp_body.first)
        else
          raise "don't know how to interpolate #{x.inspect}"
        end
      end

      s(:call, s(:const, :Kernel), :sprintf, s(:arglist, s(:str, literals.join('')), *expressions))
    end

    def compile_call(target, method, args)
      check!(method, Symbol)
            
      target = Sexp.new(:self) unless target

      if args
        check_sexp!(args, :arglist)
        args = args.sexp_body if args.sexp_type == :arglist
      else
        args = []
      end

      CallExpression.new("rb_funcall", compile(target), compile__intern(method), args.length, args.map { |a| compile(a) })
    end

    # ranges
    def compile__range(first, last, exclude_end)
      CallExpression.new('rb_range_new', compile(first), compile(last), exclude_end ? 1 : 0)
    end

    def compile_dot2(first, last)
      compile__range(first, last, false)
    end

    def compile_dot3(first, last)
      compile__range(first, last, true)
    end

    # control structures
    def compile_if(test, true_x, false_x)
      IfExpression.new(compile(test), compile(true_x), compile(false_x))
    end

    private

    def compile__intern(symbol)
      symbol = symbol.to_s
  
      # the ID of one-character symbols is the ASCII value of the character
      if symbol.length == 1
        SimpleExpression.new("'#{symbol}'")    # TODO should escape
      else
        CallExpression.new('rb_intern', symbol.inspect)
      end
    end

    def check!(value, against)
      raise "#{value} must match #{against}" unless against === value
    end

    def check_sexp!(sexp, t)
      raise "#{sexp} should have type #{t}" unless sexp.sexp_type == t
    end

    def format_escape(s)
      s.gsub('%', '%%')
    end

    def s(*args)
      Sexp.new(*args)
    end
  end 
end
