# stuff that goes at the top level of a C file
module RubyNative
  class Toplevel
  
    def to_s
      raise "not implemented; abstract"
    end

    protected

    def locals_decl(locals_used)
      return '' if locals_used.empty?

      locals_map = locals_used.map { |name, variable| variable.declaration }

      "/* locals used: #{locals_used.map { |n, v| "#{n} = #{v.id}" }.join(', ')} */\n  VALUE #{locals_map.join(",\n    ")};"
    end

  end
end
