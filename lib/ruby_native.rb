require 'rubygems'
require 'ruby_parser'

def puts_tabbed(io, tab, s)
  if tab <= 0
    io.puts s
  else
    io.puts "#{'.   ' * tab}#{s}"
  end
end

def pp_sexp(io, sexp, tab = 0)
  puts_tabbed io, tab, "> #{sexp.sexp_type.to_s}"
  
  sexp.sexp_body.each do |b|
    if b.is_a?(Sexp)
      pp_sexp io, b, tab + 1
    else
      puts_tabbed io, tab + 1, b.inspect
    end
  end
end

for name in %w(
  expression
    *_expression

  statement
    *_statement

  toplevel
    *_toplevel

  *
)
  for file in Dir.glob(File.join(File.dirname(__FILE__), "ruby_native/#{name}.rb"))
    require file
  end
end
