require File.join(File.dirname(__FILE__), '../../lib/ruby_native')

def l(v)
  s(:c_literal, v)
end

def s(*args)
  Sexp.new(*args)
end

describe RubyNative::ExpressionCompiler do

  subject do
    RubyNative::ExpressionCompiler.new
  end

  {
    nil => 'Qnil',

    s(:nil) => 'Qnil',
    s(:true) => 'Qtrue',
    s(:false) => 'Qfalse',

    s(:lit, 1) => 'LONG2FIX(1)',
    s(:str, 'fish') => 'rb_str_new2("fish")',
    s(:lit, :fish) => 'ID2SYM(rb_intern("fish"))',
    s(:lit, :+) => "ID2SYM('+')",

    s(:self) => 'self',
    s(:if, l('?1'), l('?2'), l('?3'))  => '(RTEST(?1) ? ?2 : ?3)',
    s(:call, l('?1'), :fish, s(:arglist, l('?2'))) => 'rb_funcall(?1, rb_intern("fish"), 1, ?2)',
    s(:call, l('?1'), :+, s(:arglist, l('?2'))) => %{rb_funcall(?1, '+', 1, ?2)},

    s(:while, l('?1'), l('?2'), true) => "({\nwhile(RTEST(?1)) ?2;\n\nQnil;\n})",
    s(:while, l('?1'), l('?2'), false) => "({\ndo {\n?2;\n\n} while(RTEST(?1));\nQnil;\n})",

    s(:until, l('?1'), l('?2'), true) => "({\nwhile(!RTEST(?1)) ?2;\n\nQnil;\n})",
    s(:until, l('?1'), l('?2'), false) => "({\ndo {\n?2;\n\n} while(!RTEST(?1));\nQnil;\n})",

    s(:block, l('?1'), l('?2'), l('?3')) => "?1, ?2, ?3",

  }.each do |input, output|
    it "should compile #{input.inspect} to #{output.inspect}" do
      input = RubyParser.new.parse(input) if input.is_a?(String)
      subject.compile(input).to_s.should == output
    end
  end

end
