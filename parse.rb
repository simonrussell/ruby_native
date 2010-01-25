#!/usr/bin/env ruby
require 'lib/ruby_native'

pp_sexp STDOUT, RubyParser.new.parse(ARGV.join(' '))
