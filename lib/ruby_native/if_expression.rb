module RubyNative
  class IfExpression < Expression

    def initialize(test, true_x, false_x)
      @test = test
      @true_x = true_x
      @false_x = false_x
    end

    def to_s
      "(RTEST(#{@test}) ? #{@true_x} : #{@false_x})"
    end

  end
end
