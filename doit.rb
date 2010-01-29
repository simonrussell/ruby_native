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
      Mymodule.bootstrap(self)

      Benchmark.bmbm do |benchmark|
        benchmark.report 'interpreted' do
          MULTIPLE.times { Interpreted.nested_loop(16) }
        end

        benchmark.report 'compiled' do
          MULTIPLE.times { Compiled.nested_loop(16) }
        end
      end
    else
      Mymodule.bootstrap(self)
      puts Compiled.fib4(40)
    end
  else
    puts File.read('mymodule/mymodule.c')
    puts gcc_output
  end
else
  puts run_output
end
