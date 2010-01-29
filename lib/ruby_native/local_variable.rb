module RubyNative
  class LocalVariable
    attr_reader :name, :id

    def initialize(name, id)
      @name = name
      @id = id
      @scoped = (name !~ /^!/)
    end

    def scoped?
      !!@scoped
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
