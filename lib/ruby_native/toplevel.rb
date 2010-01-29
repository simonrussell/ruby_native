# stuff that goes at the top level of a C file
module RubyNative
  class Toplevel
  
    def to_s
      raise "not implemented; abstract"
    end

    protected

    def locals_decl(locals_used)
      return '' if locals_used.empty?

      locals_map = locals_used.map do |name, id|
        case name
        when /^!(.+)/
          "local_#{id} = Qnil"
        else
          "*local_#{id} = _local_ptr(scope, SYM(#{id}, #{name.inspect}))"
        end
      end

      "/* locals used: #{locals_used.inspect} */\n  VALUE #{locals_map.join(",\n    ")};"
    end

  end
end
