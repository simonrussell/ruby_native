require File.join(File.dirname(__FILE__), '../spec_helper')

describe RubyNative::ReturnStatement do

  subject { RubyNative::ReturnStatement.new('fish') }

  it "should compile correctly" do
    subject.to_s.should == "return fish;\n"
  end

end

