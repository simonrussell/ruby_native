#!/usr/bin/env ruby
require 'lib/ruby_native'

code = %{
class Compiled
  class << self
    #{File.read('methods.rb')}
  end
end
}

parsed = RubyNative::Reader.from_string(code)
#pp_sexp STDERR, parsed

unit = RubyNative::UnitToplevel.new
unit.file_scope_name = unit.method_definition([], parsed)
puts unit
