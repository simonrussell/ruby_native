require File.join(File.dirname(__FILE__), '../spec_helper')

describe RubyNative::FunctionToplevel do

  subject { RubyNative::FunctionToplevel.new("myfunc", "mybody;") }

  it "should compile correctly" do
    subject.to_s.should == "VALUE myfunc(VALUE self) {\n  mybody;}\n"
  end

end

