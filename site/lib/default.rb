# All files in the 'lib' directory will be loaded
# before nanoc starts compiling.
require 'rubygems'
require 'bundler/setup'

require 'active_support/all'

Time.zone = "Eastern Time (US & Canada)"

Encoding.default_external = Encoding::UTF_8
