require 'serverspec'
require 'pathname'
require 'json'
require 'rubygems/dependency_installer'

include Serverspec::Helper::Exec
include Serverspec::Helper::DetectOS

installer = Gem::DependencyInstaller.new
installer.install('machine_tag')
Gem.clear_paths

require 'machine_tag'
