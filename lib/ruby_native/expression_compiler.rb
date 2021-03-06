module RubyNative
  class ExpressionCompiler
    attr_reader :scope
    
    def initialize(unit, outer_scope = nil)
      @unit = unit
      @scope = Scope.new(@unit, outer_scope)
    end
  
    def bulk_compile(sexps)
      sexps.map { |sexp| compile(sexp) }
    end

    def compile(sexp)
      return compile_nil if sexp.nil?

      sexp = send("transform_#{sexp.sexp_type}", *sexp.sexp_body) while respond_to?("transform_#{sexp.sexp_type}")

      if respond_to?("compile_#{sexp.sexp_type}")
        send("compile_#{sexp.sexp_type}", *sexp.sexp_body)
      else
        raise "don't know how to compile #{sexp} on line #{sexp.line} of `#{sexp.file}'"
      end
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
      when Float
        CallExpression.new('rb_float_new', value)
      when String
        SimpleExpression.new("rb_str_new2(#{value.inspect})")
      when Symbol
        SimpleExpression.new("ID2SYM(#{@unit.compile__intern(value)})")
      when Range
        compile__range(s(:lit, value.first), s(:lit, value.last), value.exclude_end?)
      when Regexp
        CallExpression.new("rb_reg_new", value.to_s.inspect, value.to_s.length, 0)
      else
        raise "don't know how to compile literal #{value.inspect} (#{value.class})"
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
        CallExpression.new('rb_const_get', SimpleExpression.new('SELF_CLASS'), @unit.compile__intern(name))
      end
    end

    def compile_cdecl(name, value)
      CallExpression.new('rb_const_set', SimpleExpression.new('SELF_CLASS'), @unit.compile__intern(name), compile(value))
    end

    def transform_hash(*keys_values)
      s(:call, s(:const, :Hash), :[], s(:arglist, *keys_values))
    end

    def compile_array(*values)
      splat = remove_splat!(values)
      
      if splat
        compile(s(:call, s(:const, :Array), :[], s(:arglist, s(:splat, splat))))
      else
        CallExpression.new('rb_ary_new3', values.length, bulk_compile(values))
      end
    end

    def compile_gvar(name)
      CallExpression.new("rb_gv_get", name.to_s[1..-1].inspect)
    end

    def compile_ivar(name)
      CallExpression.new('rb_ivar_get', 'self', @unit.compile__intern(name))
    end

    def compile_iasgn(name, value)
      CallExpression.new('rb_ivar_set', 'self', @unit.compile__intern(name), compile(value))
    end

    def compile_colon2(target, name)
      # TODO this should do a funcall if target is not a module or class
      CallExpression.new('rb_const_get', compile(target), @unit.compile__intern(name))
    end

    def transform_match2(target, value)     # optimization for =~
      s(:call, target, :=~, s(:arglist, value))
    end

    def transform_match3(target, value)     # optimization for =~
      s(:call, target, :=~, s(:arglist, value))
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
        args = args.sexp_body
      else
        args = []
      end

      splat_arg = remove_splat!(args)

      if splat_arg 
        CallExpression.new('splat_funcall', compile(target), @unit.compile__intern(method), compile(splat_arg), args.length, *bulk_compile(args))
      else
        case args.length
        when 0, 1, 2, 3
          CallExpression.new("fast_funcall#{args.length}", compile(target), @unit.compile__intern(method), *bulk_compile(args))
        else
          CallExpression.new("rb_funcall", compile(target), @unit.compile__intern(method), args.length, bulk_compile(args))
        end
      end
    end

    def compile_iter(call, blockargs, block_body = nil)
      raise "call must be a call!" unless call.sexp_type == :call

      CallExpression.new('rb_iterate', 
        @unit.iter(@scope, call),
        'scope',
        @unit.block(@scope, blockargs, block_body, true), 
        'scope'
      )
    end

    def compile_yield(value = nil)
      CallExpression.new('rb_yield', value ? compile(value) : SimpleExpression.new('Qundef'))
    end

    def compile_svalue(value)   # use for x = 1,2 ===> x = [1,2]
      value
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
    def compile_for(target, blockargs, body = nil)
      CallExpression.new('rb_block_call', compile(target), @unit.compile__intern(:each), 0, 'NULL', @unit.block(@scope, blockargs, body, false), 'scope')
    end

    def transform_break(x)
      # TODO not implemented correctly
      s(:return, x)
    end

    def compile_return(x)
      # TODO not implemented correctly
      StatementExpression.new(
        SequenceStatement.new(
          ReturnStatement.new(compile(x)),
          ExpressionStatement.new(compile_nil) 
        )
      )
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
      SimpleExpression.new(@scope.local_variable!(name))
    end

    def compile_lasgn(name, value)
      make_local_set(name, compile(value))
    end

    def compile_masgn(assigns, expression)
      raise "expression must be either array or to_ary" unless [:array, :to_ary].include?(expression.sexp_type)

      raise "don't know how to do anything other than array masgn" unless assigns.sexp_type == :array
      assigns = assigns.sexp_body

      GroupingExpression.new(
        compile_lasgn("!masgn", expression),
        masgn_assigns(assigns, compile_lvar('!masgn')),
        compile_lvar("!masgn")
      )
    end
    
    def transform_attrasgn(target, method, args)
      s(:call, target, method, args)
    end


    def compile_to_ary(expression)
      CallExpression.new('rb_ary_to_ary', compile(expression))
    end

    # definitions
    def compile_module(name, body)
      CallExpression.new(
        @unit.class_definition(body),
        CallExpression.new('rb_define_module_under', SimpleExpression.new('SELF_CLASS'), name.to_s.inspect)
      )
    end

    def compile_class(name, parent, body)
      parent ||= s(:const, :Object)

      CallExpression.new(
        @unit.class_definition(body),
        CallExpression.new('rb_define_class_under',
          SimpleExpression.new('SELF_CLASS'),          
          name.to_s.inspect,
          compile(parent)
        )
      )
    end

    def compile_sclass(singleton, body)
      CallExpression.new(
        @unit.class_definition(body),
        CallExpression.new('rb_singleton_class', compile(singleton))
      )      
    end

    def transform_defn(name, args, body)
      s(:defs, s(:c_literal, 'SELF_CLASS'), name, args, body)
    end

    def compile_defs(target, name, args, body)
      args = args.sexp_body

      raise "can't compile block arg" if args.any? { |a| a.to_s =~ /^&/ }
      raise "can't compile varargs yet" if args.any? { |a| a.to_s =~ /^\*/ }
      raise "can't compile default args yet" if args.last.is_a?(Sexp)
 
      @unit.comment("DEFINE #{name}")
      GroupingExpression.new(
        CallExpression.new('rb_define_method', 
          compile(target),
          name.to_s.inspect,   # TODO escape properly
          @unit.method_definition(args, body),     # anonymous, because we don't actually know what class we're in, might be clashes
          args.length
        ),
        compile_nil
      )
    end

    def compile_scope(body = nil)
      compile(body)
    end

    def masgn_assigns(assigns, source)
      return compile_nil if assigns.nil?

      index = -1

      GroupingExpression.new(
        *assigns.map do |assign|
          index += 1

          case assign.sexp_type
          when :lasgn
            make_local_set(assign.sexp_body.first, CallExpression.new('array_element', source, index))
          when :splat
            make_local_set(assign.sexp_body.first.sexp_body.first, CallExpression.new('array_tail', source, index))
          else
            raise "don't know how to masgn #{assign}"
          end
        end
      )
    end

    # exceptions

    def compile_ensure(block_body, ensured_body)
      CallExpression.new('rb_ensure',
        @unit.block(@scope, nil, block_body, false),
        'scope',
        @unit.block(@scope, nil, ensured_body, false),
        'scope'
      )
    end

    def compile_rescue(*res_bodies)
      block_body = (!res_bodies.empty? && res_bodies.first.sexp_type != :resbody && res_bodies.shift) || nil
      else_body = (!res_bodies.empty? && res_bodies.last.sexp_type != :resbody && res_bodies.pop) || nil
      raise "don't know how to compile rescue 'else' yet #{else_body}" if else_body

      all_handled = []    # have to do it this way, because Sexps are arrays
      res_bodies.each do |resbody| 
        resbody.sexp_body.first << s(:const, :StandardError) if resbody.sexp_body.first.sexp_body.empty?    # default exception to handle
        all_handled += resbody.sexp_body.first.sexp_body.select { |t| t.sexp_type == :const }
      end

      # build resbodies into a bunch of if statements

      case_bodies = res_bodies.inject(nil) do |expression, resbody|
        s(:if,
          s(:nil),
          resbody.sexp_body.last,
          expression
        )
      end

      GroupingExpression.new(
        CallExpression.new('rb_rescue2',
          @unit.block(@scope, nil, block_body, false),
          'scope',
          @unit.rescue_handler(@scope, case_bodies),
          'scope',
          bulk_compile(all_handled),
          '(VALUE)0'
        )
      )
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

    def make_local_set(name, value)
      LocalSetExpression.new(@scope.local_variable!(name), value)
    end

    def remove_splat!(a)
      a.last && a.last.sexp_type == :splat && a.pop.sexp_body.first || nil
    end
  end 
end
