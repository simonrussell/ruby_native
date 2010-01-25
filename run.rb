#!/usr/bin/env ruby
require 'lib/ruby_native'

#code = '"hello world #{1 + 1} a bit #{2 + 1}"'
#code = 'puts self.inspect'
#code = '1 + 1'
#code = '"a" ? "b" : "c"'
#code = 'while false; puts x; end'

code = %{
  if gets == "fish\n"
    puts 'fishy!'
  else
    puts 'happy!'
  end
}

parsed = RubyNative::Reader.from_string(code)
pp_sexp STDERR, parsed

puts "#include <ruby.h>"

puts "static VALUE mymethod(VALUE self) {\n  return "
puts RubyNative::ExpressionCompiler.new.compile(parsed)
puts ";\n}\n"

puts %{
void Init_mymodule(void)
{
  VALUE module = rb_define_module("Mymodule");

  rb_define_module_function(module, "run", mymethod, 0);
}
}


