#!/usr/bin/env ruby
require 'lib/ruby_native'

parsed = RubyParser.new.parse(ARGV.join(' '))
pp_sexp STDOUT, parsed
puts "-------------------------"

unit = RubyNative::UnitToplevel.new
unit.scoped_block('zzzzzz', parsed)
puts unit
