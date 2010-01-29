module RubyNative
  class LocalVariable
    attr_reader :name, :id

    def initialize(name, id)
      @name = name
      @id = id
      @scoped = false
    end

    def scoped?
      !!@scoped
    end

    def scoped!
      @scoped = true
    end

    def declaration
      if @scoped
        "*local_#{@id} = _local_ptr(scope, SYM(#{@id}, #{@name.inspect}))"
      else
        "local_#{@id} = Qnil"
      end
    end

    def to_s
      if @scoped
        "(*local_#{@id})"
      else
        "local_#{@id}"
      end
    end

  end
end
