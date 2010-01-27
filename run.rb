#!/usr/bin/env ruby
require 'lib/ruby_native'

code = %{
  def compiled_fib(n)
    n < 2 ? n : fib(n-1) + fib(n-2)
  end
}

parsed = RubyNative::Reader.from_string(code)
pp_sexp STDERR, parsed

puts <<EOC
#include <ruby.h>

#define TO_BOOL(x) ((x) ? Qtrue : Qfalse)

// these are really just aliases, but it looks nicer (could also do more checking?)
static VALUE _local_get(VALUE scope, VALUE name)
{
  return rb_hash_lookup(scope, name);
}

static VALUE _local_set(VALUE scope, VALUE name, VALUE value)
{
  return rb_hash_aset(scope, name, value);
}

static VALUE _local_defined(VALUE scope, VALUE name)
{
  // cut and paste from hash.c, because we don't have access to it
  return TO_BOOL(st_lookup(RHASH(scope)->tbl, name, 0));
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
      case '+':   return LONG2NUM(a + b);
      case '-':   return LONG2NUM(a - b);
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
unit.scoped_block('file_scope', [], parsed)
puts unit

puts <<EOC
static VALUE bootstrap(VALUE self, VALUE real_self)
{
  return file_scope(real_self);
}

void Init_mymodule(void)
{
  VALUE module = rb_define_module("Mymodule");

  rb_define_module_function(module, "bootstrap", bootstrap, 1);
}
EOC
