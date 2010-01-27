#!/usr/bin/env ruby

MULTIPLE = 1 #1_000_000

def fib(n)
  n < 2 ? n : fib(n-1) + fib(n-2)
end

def fib2(n)
  curr = 0
  succ = 1

  i = 0
  while i < n
    n_curr = succ
    n_succ = curr + succ
    
    curr = n_curr
    succ = n_succ

    i += 1
  end

  curr
end

require 'benchmark' if ARGV.first == 'bm'

puts `ruby run.rb > mymodule/mymodule.c`

if $? == 0
  puts File.read('mymodule/mymodule.c')

  puts `cd mymodule && make`
  
  if $? == 0
    require 'mymodule/mymodule'

    if ARGV.first == 'bm'
      Mymodule.bootstrap(self)

      Benchmark.bmbm do |benchmark|
        benchmark.report 'interpreted' do
          MULTIPLE.times { fib2(100_000) }
        end

        benchmark.report 'compiled' do
          MULTIPLE.times { compiled_fib2(100_000) }
        end
      end
    else
      Mymodule.bootstrap(self)
      puts compiled_fib2(40)
    end
  end
end
