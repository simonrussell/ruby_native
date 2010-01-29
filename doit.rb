#!/usr/bin/env ruby

MULTIPLE = 1 #1_000_000

class Interpreted
  puts "interpreted self = " + self.inspect
  class << self
    puts "interpreted self = " + self.inspect
    eval(File.read('methods.rb'))
  end
end

require 'benchmark' if ARGV.first == 'bm'

`ruby run.rb > mymodule/mymodule.c`

if $? == 0
#  puts File.read('mymodule/mymodule.c')

  puts `cd mymodule && make`
  
  if $? == 0
    require 'mymodule/mymodule'

    if ARGV.first == 'bm'
      Mymodule.bootstrap(self)

      Benchmark.bmbm do |benchmark|
        benchmark.report 'interpreted' do
          MULTIPLE.times { Interpreted.fib3(100_000) }
        end

        benchmark.report 'compiled' do
          MULTIPLE.times { Compiled.fib3(100_000) }
        end
      end
    else
      Mymodule.bootstrap(self)
      puts Compiled.fib4(40)
    end
  end
end
