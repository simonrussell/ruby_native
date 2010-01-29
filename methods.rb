def fib3(n)
  curr = 0
  succ = 1

  i = 0
  while i < n
    curr, succ = succ, curr + succ

    i += 1
  end

  curr
end

def fib4(n)
  curr = 0
  succ = 1

  n.times do |i|
    curr, succ = succ, curr + succ
  end

  return curr
end

def sieve
  # from http://www.bagley.org/~doug/shootout/bench/sieve/sieve.ruby
  num = 40
  count = i = j = 0
  flags0 = Array.new(8192,1)
  k = 0
  while k < num
    k+=1
    count = 0
    flags = flags0.dup
    i = 2
    while i<8192
      i+=1
      if flags[i]
        # remove all multiples of prime: i
        j = i*i
        while j < 8192
          j += i
          flags[j] = nil
        end
        count += 1
      end
    end
  end
  count
end

def bm_sieve
  sieve
end

def nested_loop(n)
  x = 0
  n.times do
      n.times do
          n.times do
              n.times do
                  n.times do
                      n.times do
                          x += 1
                      end
                  end
              end
          end
      end
  end
  x
end

def bm_nested_loop
  nested_loop(16)
end

def tak(x, y, z)
  unless y < x
    z
  else
    tak( tak(x-1, y, z),
         tak(y-1, z, x),
         tak(z-1, x, y))
  end
end

def bm_tak
  tak(18, 9, 0)
end

