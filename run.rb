#!/usr/bin/env ruby
require 'lib/ruby_native'

#code = '"hello world #{1 + 1} a bit #{2 + 1}"'
#code = 'puts self.inspect'
#code = '1 + 1'
#code = '"a" ? "b" : "c"'
#code = 'while false; puts x; end'

code = %{
#  puts 1..2
#  puts 'a'...'b'
#  x = 1
#  x
  puts({ :a => 1, :b => 2 })
  puts [1,2,3]
}

parsed = RubyNative::Reader.from_string(code)
pp_sexp STDERR, parsed

puts "#include <ruby.h>

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

"

puts RubyNative::FunctionToplevel.new('mymethod', 
  RubyNative::ReturnStatement.new(  
    RubyNative::ExpressionCompiler.new.compile(parsed)
  )
)

puts %{
void Init_mymodule(void)
{
  VALUE module = rb_define_module("Mymodule");

  rb_define_module_function(module, "run", mymethod, 0);
}
}


