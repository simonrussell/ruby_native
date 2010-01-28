1 + 1

puts (class X
  x = 123

  def show_x
    puts defined?(x)
  end
end).inspect

X.new.show_x
