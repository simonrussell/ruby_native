#!/usr/bin/env ruby
require 'lib/ruby_native'

#code = '"hello world #{1 + 1} a bit #{2 + 1}"'
#code = 'puts self.inspect'
#code = '1 + 1'
#code = '"a" ? "b" : "c"'
#code = 'while false; puts x; end'

code = %{
  puts 1..2
  puts 'a'...'b'
}

parsed = RubyNative::Reader.from_string(code)
pp_sexp STDERR, parsed

puts "#include <ruby.h>"

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


