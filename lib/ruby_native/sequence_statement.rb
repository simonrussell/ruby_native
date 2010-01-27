module RubyNative
  class SequenceStatement < Statement

    def initialize(*statements)
      @statements = statements.flatten
    end

    def to_s
      @statements.join('');
    end

  end
end
