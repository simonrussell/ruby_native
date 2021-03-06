#!/usr/bin/env ruby

MULTIPLE = 1 #1_000_000

class Interpreted
  class << self
    eval(File.read('methods.rb'))
  end
end

require 'benchmark' if ARGV.first == 'bm'

run_output = `ruby run.rb > mymodule/mymodule.c`

if $? == 0
  gcc_output = `cd mymodule && make`
  
  if $? == 0
    require 'mymodule/mymodule'

    if ARGV.first == 'bm'
      Mymodule.send(Mymodule.methods.detect { |m| m =~ /^bootstrap_/ }, self)

      bm = ARGV.last

      Benchmark.bmbm do |benchmark|
        benchmark.report 'interpreted' do
          MULTIPLE.times { Interpreted.send("bm_#{bm}") }
        end

        benchmark.report 'compiled' do
          MULTIPLE.times { Compiled.send("bm_#{bm}") }
        end
      end
    else
      Mymodule.send(Mymodule.methods.detect { |m| m =~ /^bootstrap_/ }, self)

      puts Compiled.fib4(40)
    end
  else
    #puts File.read('mymodule/mymodule.c')
    puts gcc_output
  end
else
  puts run_output
end
