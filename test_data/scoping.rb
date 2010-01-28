$scoping = {}

x = 12

class A
  $scoping['x inside A'] = !defined?(x)

  def meth
    $scoping['x inside A#meth'] = !defined?(x)
  end
end

class B
  x = 14

  $scoping['x inside B'] = defined?(x)
  $scoping['x inside B has value 14'] = (x == 14)

  def meth
    $scoping['x inside B#meth'] = !defined?(x)
  end
end

$scoping['outer x has value 12'] = (x == 12)

for a in [1]
  x = 15
  y = 4   # leaks into outer scope
end

$scoping['outer x has value 15'] = (x == 15)
$scoping['outer y not defined'] = defined?(y)

[1].each do |b|
  x = 16
  z = 4   # leaks into outer scope
end

$scoping[__LINE__] = !defined?(b)
$scoping[__LINE__] = (x == 16)
$scoping[__LINE__] = !defined?(z)


A.new.meth
B.new.meth


$scoping.each do |k, v|
  puts "#{!!v}: #{k}"
end
