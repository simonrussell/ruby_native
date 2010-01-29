module RubyNative
  class Scope

    def initialize(unit, parent = nil)
      @unit = unit
      @parent = parent
      @variables = {}
    end

    def [](name)
      @variables[name.to_s] || (@parent && @parent[name])
    end

    def has?(name)
      @variables[name.to_s]
    end

    def has_or_parent?(name)
      has?(name) || (@parent && @parent.has_or_parent?(name))
    end

    def local_variable!(name)
      name = name.to_s

      if @variables.key?(name)
        @variables[name]
      else
        parent_variable = @parent && @parent[name]
        parent_variable.scoped! if parent_variable

        @variables[name] = parent_variable || LocalVariable.new(name, @unit.symbol(name))
      end
    end

    def empty?
      @variables.empty?
    end

    def map(&block)
      @variables.map(&block)
    end

    def any_exported?
      @variables.values.any? { |v| v.scoped? }
    end

    def names
      @variables.keys
    end

    def declaration
      if any_exported?
        "scope = _local_alloc(#{@parent ? 'outer_scope' : 'Qnil'}, self)"
      else
        "scope = #{@parent ? 'outer_scope' : 'Qnil'}"
      end
    end
  
  end
end
