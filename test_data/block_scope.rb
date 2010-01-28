def test1
  x = 1

  [1,2,3].each do |x|
  end

  x == 3
end

def test2
  x = 1

  [1,2,3].each do |y|
    x = y
  end

  x == 3
end

def test3
  [1,2,3].each do |y|
    x = y
  end

  !defined?(x)
end

def test4
  [1,2,3].each do |y|
    x = y
    return !!defined?(x)
  end
end

def test5
  [1,2,3].each do |x|
  end

  !defined?(x)
end


puts test1
puts test2
puts test3
puts test4
puts test5

