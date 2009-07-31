# gl_tail.rb - OpenGL visualization of your server traffic
# Copyright 2007 Erlend Simonsen <mr@fudgie.org>
#
# Licensed under the General Public License v2 (see LICENSE)
#

begin
  require 'rubygems'
rescue LoadError
  puts "Rubygems missing. Please install."
  puts "Ubuntu:\n  sudo apt-get install rubygems"
end

gem_version = Gem::RubyGemsVersion.split('.')

if gem_version[0].to_i == 0 && gem_version[1].to_i < 9 || (gem_version[0].to_i == 0 && gem_version[1].to_i >= 9 && gem_version[2].to_i < 2)
  puts "rubygems too old to build ruby-opengl. Please update."
  puts "Ubuntu:"
  puts "  sudo gem update --system"
  exit
end

begin
  gem 'net-ssh-gateway', '> 1.0'
  require 'net/ssh'
  require 'net/ssh/gateway'
rescue LoadError
  puts "Missing gem net-ssh."
  puts "Ubuntu:"
  puts "  sudo gem install -y net-ssh-gateway -r"
  exit
end

begin
  require 'file/tail'
rescue LoadError
  puts "Missing gem file-tail."
  puts "Ubuntu:"
  puts "  sudo gem install -y file-tail -r"
  exit
end

begin
  require 'json'
rescue LoadError
  puts "Missing gem json-jruby"
  puts "Ubuntu:"
  puts "  sudo gem install -y json-jruby -r"
  exit
end

$:.unshift(File.dirname(__FILE__)) # this should be obsolete once its a gem

# load our libraries
require 'organism/monitor_categories'
require 'organism/config'
require 'organism/organism_enumerable'
require 'organism/sources/base'
require 'organism/sources/ssh'
require 'organism/parser'
require 'gltail/http_helper'
Dir.glob(File.join("lib/gltail/parsers/*.rb")).each {|f| require f }




