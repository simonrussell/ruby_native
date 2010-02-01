#!/usr/bin/env ruby
require 'lib/ruby_native'

input_path = 'test_module'
output_path = 'test_module-native'

def input_files(path)
  path = File.join(path, '/')

  Dir.glob(File.join(path, '**/*')).select { |f| File.file?(f) }.map { |f| f[path.length .. -1] }.sort
end

unit = RubyNative::UnitToplevel.new

def ruby_source?(filename)
  filename =~ /\.rb$/
end

def compile_and_stub(unit, source_path, filename, dest_path)
  source_code = File.read(File.join(source_path, filename))
  parsed = RubyNative::Reader.from_string(source_code, File.expand_path(File.join(dest_path, filename)))
  file_function_name = unit.file(parsed)

  File.open(File.join(dest_path, filename), 'w') do |f|
    f.puts <<EOS
#!/usr/bin/env ruby
require File.expand_path(File.join(File.dirname(__FILE__), '#{'../' * filename.count('/')}_native/mymodule.so'))
Mymodule.#{file_function_name}(self)
EOS
  end
end

def copy(source_path, filename, dest_path)
  FileUtils.cp File.join(source_path, filename), File.join(dest_path, filename)
end

input_files(input_path).each do |filename|
  FileUtils.mkdir_p(File.dirname(File.join(output_path, filename)))

  if ruby_source?(filename)
    puts "R #{filename}"

    compile_and_stub(unit, input_path, filename, output_path)
  else
    puts "C #{filename}"

    copy(input_path, filename, output_path)
  end
end

FileUtils.mkdir_p(File.join(output_path, '_native'))

File.open File.join(output_path, '_native/mymodule.c'), 'w' do |f|
  f.puts unit
end

File.open File.join(output_path, '_native/extconf.rb'), 'w' do |f|
  f.puts %{
#!/usr/bin/env ruby
require 'mkmf'
extension_name = 'mymodule'
dir_config(extension_name)
create_makefile(extension_name)
}  
end

`cd #{File.join(output_path, '_native')} && /usr/bin/env ruby extconf.rb && make`
