#!/usr/bin/env ruby

require 'mkmf'

extension_name = 'mymodule'

dir_config(extension_name)
#have_library('stdc++')

create_makefile(extension_name)
