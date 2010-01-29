# stuff that goes at the top level of a C file
module RubyNative
  class Toplevel
  
    def to_s
      raise "not implemented; abstract"
    end

    protected

    def locals_decl(locals_used)
      return '' if locals_used.empty?
    
      "/* locals used: #{locals_used.inspect} */\n  VALUE #{locals_used.map { |name, id| "*local_#{id} = _local_ptr(scope, SYM(#{id}, #{name.inspect}))" }.join(",\n    ")};"
    end

  end
end
