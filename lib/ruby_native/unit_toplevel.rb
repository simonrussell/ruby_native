module RubyNative
  class UnitToplevel < Toplevel

    def initialize
      @block_id = 0
      @blocks = []
      @bootstraps = []

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

    def file(body)
      file_scope_name = method_definition([], body)
      bootstrap_name = "bootstrap_#{block_id!}"

      @blocks << BootstrapToplevel.new(bootstrap_name, file_scope_name)
      @bootstraps << bootstrap_name

      bootstrap_name
    end

    def method_definition(args, body_expression)
      named_method_definition("rn_method_#{block_id!}", args, body_expression)
    end

    def named_method_definition(name, args, body_expression)
      compiler = ExpressionCompiler.new(self)
      args.each { |a| compiler.scope.local_variable!(a) }
      body = compiler.compile(body_expression)

      args_scopers = compiler.compile(
        s(:block, 
          *args.map { |a| s(:lasgn, a, s(:c_literal, a.to_s)) }
        )
      )

      @blocks << MethodDefinitionToplevel.new(name, args, args_scopers, compiler.scope, body)
      name
    end

    def class_definition(body)
      name = "rn_class_#{block_id!}"
      compiler = ExpressionCompiler.new(self)
      compiled_body = compiler.compile(body)

      @blocks << ClassDefinitionToplevel.new(name, compiler.scope, compiled_body)
      name
    end

    def block(outer_scope, args, body, scoped)
      name = "rn_block_#{block_id!}"
      compiler = ExpressionCompiler.new(self, outer_scope)
      
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

      @blocks << (scoped ? ScopedBlockToplevel : BlockToplevel).new(name, arg_scopers, compiler.scope, compiled_body)
      name
    end

    def iter(outer_scope, body)
      name = "rn_iter_#{block_id!}"
      compiler = ExpressionCompiler.new(self, outer_scope)
      compiled_body = compiler.compile(body)

      @blocks << IterToplevel.new(name, compiler.scope, compiled_body)
      name
    end

    def rescue_handler(outer_scope, cases)
      name = "rn_rescue_#{block_id!}"
      compiler = ExpressionCompiler.new(self, outer_scope)
      compiled_cases = compiler.compile(cases)

      @blocks << RescueToplevel.new(name, compiler.scope, compiled_cases)
      name
    end

    def comment(s)
      @blocks << "/*\n#{s.gsub('*/', '* /')}\n*/\n"           # just in case
    end

    def to_s
      unit_prefix_code + setup_symbols_code + @blocks.join("\n") + unit_suffix_code
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

    def unit_prefix_code
<<EOC
#include <ruby.h>
#include <node.h>

#define TO_BOOL(x) ((x) ? Qtrue : Qfalse)
#define SYM(key, name)  (_symbols[key])
#define SELF_CLASS      (TYPE(self) == T_CLASS ? self : rb_funcall(self, rb_intern("class"), 0))

#define DECLARE_NODE        NODE *node, *old_node;
#define SHUFFLE_NODE(f, l)  (node = NEW_NIL(), /*RNODE(node)->nd_file = (f), */nd_set_line(node, (l)), old_node = ruby_current_node, ruby_current_node = node)
#define DESHUFFLE_NODE      (ruby_current_node = old_node)

//#define DECLARE_NODE
//#define SHUFFLE_NODE
//#define DESHUFFLE_NODE

static inline VALUE array_element(VALUE array, long index)
{
  if (index >= 0 && index < RARRAY(array)->len)
  {
    return RARRAY(array)->ptr[index];
  }
  else
  {
    return Qnil;
  }
}

static VALUE array_tail(VALUE array, long index)
{
  VALUE result;
  long tail_length;

  if (index < 0)
    index = 0;        /* really doesn't make much sense? */

  tail_length = RARRAY(array)->len - index;

  if (tail_length <= 0)
    return rb_ary_new();

  /* allocate an array the right size, copy the elements over */
  result = rb_ary_new2(tail_length);
  memcpy(RARRAY(result)->ptr, RARRAY(array)->ptr + index, tail_length * sizeof(VALUE));
  RARRAY(result)->len = tail_length;

  return result;
}

// these are really just aliases, but it looks nicer (could also do more checking?)
static VALUE _local_alloc(VALUE outer_scope, VALUE self)
{
  VALUE scope = rb_ary_new();

  rb_ary_push(scope, outer_scope);
  rb_ary_push(scope, self);
}

inline static VALUE _local_self(VALUE scope)
{
  array_element(scope, 1);
}

static VALUE _local_get(VALUE scope, ID name)
{
  VALUE *i, *end, search_for, outer_scope;

  Check_Type(scope, T_ARRAY);
  end = RARRAY(scope)->ptr + RARRAY(scope)->len;
  search_for = ID2SYM(name);

  for (i = RARRAY(scope)->ptr + 2; i < end; i += 2)
  {
    if (*i == search_for)
      return *(i + 1);
  }

  outer_scope = array_element(scope, 0);

  if (RTEST(outer_scope))   /* outer scope? */
  {
    return _local_get(outer_scope, name);
  }
  else
  {
    return Qnil;
  }
}

/* don't add it if it's not there */
static VALUE *_local_set_only(VALUE scope, VALUE search_for, VALUE value)
{
  VALUE *i, *end;

  Check_Type(scope, T_ARRAY);
  end = RARRAY(scope)->ptr + RARRAY(scope)->len;

  for (i = RARRAY(scope)->ptr + 2; i < end; i += 2)
  {
    if (*i == search_for)
    {
      if (value != Qundef)    /* we can just search, without setting */
      {
        *(i + 1) = value;
      }

      return i + 1;   /* address of var */
    }
  }

  {
    VALUE outer_scope = array_element(scope, 0);

    if (RTEST(outer_scope))
    {
      return _local_set_only(outer_scope, search_for, value);
    }
  }

  return NULL;
}

static VALUE _local_set(VALUE scope, ID name, VALUE value)
{
  VALUE search_for = ID2SYM(name);
  VALUE outer_scope;

  if (!_local_set_only(scope, search_for, value))
  {
    rb_ary_push(scope, search_for);
    rb_ary_push(scope, value);
  }

  return value;
}

static VALUE *_local_ptr(VALUE scope, ID name)
{
  VALUE search_for = ID2SYM(name);
  VALUE outer_scope;

  VALUE *result = _local_set_only(scope, search_for, Qundef);    /* try and find existing address */

  if (!result)
  {
    rb_ary_push(scope, search_for);
    rb_ary_push(scope, Qnil);

    return RARRAY(scope)->ptr + RARRAY(scope)->len - 1;   /* the address of what we just pushed */
  }
  else
  {
    return result;
  }
}

static VALUE _local_defined(VALUE scope, VALUE name)
{
  // cut and paste from hash.c, because we don't have access to it
  //return TO_BOOL(st_lookup(RHASH(scope)->tbl, name, 0));
  return Qundef;
}

#define RN_OPTIMIZE

inline static VALUE fast_funcall0(VALUE target, ID method)
{
  return rb_funcall2(target, method, 0, NULL);
}

static VALUE fast_funcall1(VALUE target, ID method, VALUE arg)
{
#ifdef RN_OPTIMIZE
  // Just as an example
  if (FIXNUM_P(target) && FIXNUM_P(arg))
  {
    long a = FIX2LONG(target);
    long b = FIX2LONG(arg);
    
    switch(method)
    {
//      case '+':   return LONG2NUM(a + b);
//      case '-':   return LONG2NUM(a - b);
      case '<':   return TO_BOOL(a < b);
      case '>':   return TO_BOOL(a > b);
    }
  }    
#endif

  // just do the work  
  return rb_funcall2(target, method, 1, &arg);
}

inline static VALUE fast_funcall2(VALUE target, ID method, VALUE arg0, VALUE arg1)
{
  VALUE args[] = { arg0, arg1 };

  return rb_funcall2(target, method, 2, args);
}

inline static VALUE fast_funcall3(VALUE target, ID method, VALUE arg0, VALUE arg1, VALUE arg2)
{
  VALUE args[] = { arg0, arg1, arg2 };

  return rb_funcall2(target, method, 3, args);
}

EOC
    end

    def unit_suffix_code
      bootstraps_code = @bootstraps.map { |b| "rb_define_module_function(module, #{b.inspect}, #{b}, 1);" }.join("\n")

<<EOC
void Init_mymodule(void)
{
  VALUE module;
  
  setup_symbols();

  module = rb_define_module("Mymodule");

  #{bootstraps_code}
}
EOC
    end

  end
end
