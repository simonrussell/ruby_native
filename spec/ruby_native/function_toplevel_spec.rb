require File.join(File.dirname(__FILE__), '../spec_helper')

describe RubyNative::FunctionToplevel do

  subject { RubyNative::FunctionToplevel.new("myfunc", [], RubyNative::SimpleExpression.new("mybody")) }

  it "should compile correctly" do
    subject.to_s.should == "static VALUE myfunc(VALUE self) {\n  return mybody;\n}\n"
  end

end

