module RubyNative
  class ExpressionCompiler
    
    def initialize(unit)
      @unit = unit
    end

    def bulk_compile(sexps)
      sexps.map { |sexp| compile(sexp) }
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
        SequenceStatement.new(
          WhileStatement.new(
            compile(test),
            ExpressionStatement.new(compile(body)),
            test_before,
            not_test
          ),
          ExpressionStatement.new(
            compile_nil
          )
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
        SimpleExpression.new("ID2SYM(#{@unit.compile__intern(value)})")
      when Range
        compile__range(s(:lit, value.first), s(:lit, value.last), value.exclude_end?)
      else
        raise "don't know how to compile literal #{value.inspect}"
      end
    end

    alias :compile_str :compile_lit

    def compile_const(name)
      case name
      # modules
      when :Kernel
        SimpleExpression.new("rb_m#{name}")
      
      # classes
      when :Object, :Array, :Hash, :Fixnum, :Float
        SimpleExpression.new("rb_c#{name}")

      else
        CallExpression.new('rb_const_get', CallExpression.new('CLASS_OF', compile_self), @unit.compile__intern(name))
      end
    end

    def transform_hash(*keys_values)
      s(:call, s(:const, :Hash), :[], s(:arglist, *keys_values))
    end

    def compile_array(*values)
      CallExpression.new('rb_ary_new3', values.length, bulk_compile(values))
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

    # calling/iterating

    def compile_call(target, method, args)
      check!(method, Symbol)
            
      target = Sexp.new(:self) unless target

      if args
        check_sexp!(args, :arglist)
        args = args.sexp_body if args.sexp_type == :arglist
      else
        args = []
      end

      if args.length == 1
        CallExpression.new('fast_funcall1', compile(target), @unit.compile__intern(method), *bulk_compile(args))
      else
        CallExpression.new("rb_funcall", compile(target), @unit.compile__intern(method), args.length, bulk_compile(args))
      end
    end

    def compile_iter(call, blockargs, block_body)
      raise "not implemented"
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
    def compile_return(x)
      StatementExpression.new(ReturnStatement.new(compile(x)))  
    end

    def compile_if(test, true_x, false_x)
      IfExpression.new(compile(test), compile(true_x), compile(false_x))
    end

    def compile_and(left, right)
      StatementExpression.new(
        SequenceStatement.new(
          ExpressionStatement.new(compile(left), 'VALUE x ='),
          ExpressionStatement.new(
            IfExpression.new(
              compile_c_literal('x'),
              compile(right),
              compile_c_literal('x')
            )
          )
        )
      )
    end

    def compile_or(left, right)
      StatementExpression.new(
        SequenceStatement.new(
          ExpressionStatement.new(compile(left), 'VALUE x ='),
          ExpressionStatement.new(
            IfExpression.new(
              compile_c_literal('x'),
              compile_c_literal('x'),
              compile(right)
            )
          )
        )
      )
    end

    # local variables
    def compile_lvar(name)
      CallExpression.new('_local_get', 'scope', @unit.compile__intern(name))
    end

    def compile_lasgn(name, value)
      CallExpression.new('_local_set', 'scope', @unit.compile__intern(name), compile(value))
    end

    def compile_masgn(assigns, expression)
      raise "expression must be either array or to_ary" unless [:array, :to_ary].include?(expression.sexp_type)

      raise "don't know how to do anything other than array masgn" unless assigns.sexp_type == :array
      assigns = assigns.sexp_body

      index = -1

      GroupingExpression.new(
        compile_lasgn("!masgn", expression),
        GroupingExpression.new(
          *assigns.map do |assign|
            index += 1

            case assign.sexp_type
            when :lasgn
              CallExpression.new('_local_set', 'scope', @unit.compile__intern(assign.sexp_body.first), CallExpression.new('array_element', compile_lvar('!masgn'), index))
            when :splat
              CallExpression.new('_local_set', 'scope', @unit.compile__intern(assign.sexp_body.first.sexp_body.first), CallExpression.new('array_tail', compile_lvar('!masgn'), index))
            else
              raise "don't know how to masgn #{assign}"
            end
          end
        ),
        compile_lvar("!masgn")
      )
    end

    def compile_to_ary(expression)
      CallExpression.new('rb_ary_to_ary', compile(expression))
    end

    # definitions
    def compile_class(name, parent, body)
      parent ||= s(:const, :Object)

      CallExpression.new(
        @unit.anonymous_block([], body),
        CallExpression.new('rb_define_class_under',
          CallExpression.new('CLASS_OF', compile_self),          
          name.to_s.inspect,
          compile(parent)
        )
      )
    end

    def compile_defn(name, args, body)
      args = args.sexp_body

      raise "can't compile block arg" if args.any? { |a| a.to_s =~ /^&/ }
      raise "can't compile varargs yet" if args.any? { |a| a.to_s =~ /^\*/ }
      raise "can't compile default args yet" if args.last.is_a?(Sexp)

      GroupingExpression.new(
        CallExpression.new('rb_define_method', 
          SimpleExpression.new("(TYPE(self) == T_CLASS ? self : CLASS_OF(self))"),
          name.to_s.inspect,   # TODO escape properly
          @unit.anonymous_block(args, body),     # anonymous, because we don't actually know what class we're in, might be clashes
          args.length
        ),
        compile_nil
      )
    end

    def compile_scope(body = nil)
      return compile_nil unless body

      ScopeExpression.new(compile(body))
    end

    private

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
