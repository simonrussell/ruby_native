#!/usr/bin/env ruby
require 'lib/ruby_native'

code = %{
  def compiled_fib(n)
    n < 2 ? n : compiled_fib(n-1) + compiled_fib(n-2)
  end

  def compiled_fib2(n)
    curr = 0
    succ = 1

    i = 0
    while i < n
      n_curr = succ
      n_succ = curr + succ
      
      curr = n_curr
      succ = n_succ

      i += 1
    end

    curr
  end

  def compiled_fib3(n)
    curr = 0
    succ = 1

    i = 0
    while i < n
      curr, succ = succ, curr + succ

      i += 1
    end

    curr
  end

  def compiled_fib4(n)
    curr = 0
    succ = 1

    n.times do |i|
      curr, succ = succ, curr + succ
    end

    return curr
  end

  x, y, *z = [1,2,3,4]
  puts [x, y, z].inspect

  3.times { puts "yay!" }
  
  [1,2,3].each { |x| puts x, y }
  puts x
  { :a => :b, :c => :d }.each { |k, v| puts k.to_s + " => " + v.to_s }
}

parsed = RubyNative::Reader.from_string(code)
pp_sexp STDERR, parsed

puts <<EOC
#include <ruby.h>

#define TO_BOOL(x) ((x) ? Qtrue : Qfalse)
#define SYM(key, name)  (_symbols[key])
#define SELF_CLASS      (TYPE(self) == T_CLASS ? self : CLASS_OF(self))

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
static int _local_set_only(VALUE scope, VALUE search_for, VALUE value)
{
  VALUE *i, *end;

  Check_Type(scope, T_ARRAY);
  end = RARRAY(scope)->ptr + RARRAY(scope)->len;

  for (i = RARRAY(scope)->ptr + 2; i < end; i += 2)
  {
    if (*i == search_for)
    {
      *(i + 1) = value;
      return 1;
    }
  }

  {
    VALUE outer_scope = array_element(scope, 0);

    if (RTEST(outer_scope))
    {
      return _local_set_only(outer_scope, search_for, value);
    }
  }

  return 0;  
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

static VALUE _local_defined(VALUE scope, VALUE name)
{
  // cut and paste from hash.c, because we don't have access to it
  //return TO_BOOL(st_lookup(RHASH(scope)->tbl, name, 0));
  return Qundef;
}

#define RN_OPTIMIZE

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

EOC

unit = RubyNative::UnitToplevel.new
file_scope_name = unit.method_definition([], parsed)
puts unit

puts <<EOC
static VALUE bootstrap(VALUE self, VALUE real_self)
{
  return #{file_scope_name}(real_self);
}

void Init_mymodule(void)
{
  VALUE module;
  
  setup_symbols();

  module = rb_define_module("Mymodule");

  rb_define_module_function(module, "bootstrap", bootstrap, 1);
}
EOC
