require 'serverspec'
require 'pathname'
require 'json'
require 'rubygems/dependency_installer'

# server_spec requires Gems to be installed in a specific path so the following is needed to make machine_tag
# available for testing
installer = Gem::DependencyInstaller.new
installer.install('machine_tag')
Gem.clear_paths

require 'machine_tag'
