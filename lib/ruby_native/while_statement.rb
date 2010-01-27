module RubyNative
  class WhileStatement < Statement

    def initialize(test_x, body_statement, test_before, not_test)
      @test = test_x
      @body = body_statement
      @test_before = test_before
      @not_test = not_test
    end

    def to_s
      unless @test_before
        "do {\n#{@body}\n} while(#{test_expression});\n"    # TODO this seems to be buggy?
      else
        "while(#{test_expression}) #{@body}\n"
      end
    end

    private

    def test_expression
      "#{'!' if @not_test}RTEST(#{@test})"
    end
    
  end
end
