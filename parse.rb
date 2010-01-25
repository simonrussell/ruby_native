#!/usr/bin/env ruby
require 'lib/ruby_native'

parsed = RubyParser.new.parse(ARGV.join(' '))
pp_sexp STDOUT, parsed
puts "-------------------------"
puts RubyNative::ExpressionCompiler.new.compile(parsed)
