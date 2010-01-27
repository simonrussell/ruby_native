#!/usr/bin/env ruby

MULTIPLE = 1_000_000

def my_method
#  "hello world #{1 + 1} a bit #{2 + 1}"
#  1 + 1
#  "a" ? "b" : "c"
end

require 'benchmark' if ARGV.first == 'bm'

puts `ruby run.rb > mymodule/mymodule.c`

if $? == 0
  puts File.read('mymodule/mymodule.c')

  puts `cd mymodule && make`
  
  if $? == 0
    require 'mymodule/mymodule'

    if ARGV.first == 'bm'
      Benchmark.bmbm do |benchmark|
        benchmark.report 'interpreted' do
          MULTIPLE.times { my_method }
        end

        benchmark.report 'compiled' do
          MULTIPLE.times { Mymodule.run }
        end
      end
    else
      puts Mymodule.bootstrap(self)
    end
  end
end
