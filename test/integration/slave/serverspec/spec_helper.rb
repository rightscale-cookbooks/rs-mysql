require 'serverspec'
require 'pathname'
require 'json'
require 'rubygems/dependency_installer'

include Serverspec::Helper::Exec
include Serverspec::Helper::DetectOS

# server_spec requires Gems to be installed in a specific path so the following is needed to make mysql12 & machine_tag
# available for testing
installer = Gem::DependencyInstaller.new
installer.install('mysql2')
installer.install('machine_tag')
Gem.clear_paths

require 'machine_tag'

require 'mysql2'

def db
  @db ||= begin
    connection = ::Mysql2::Client.new(
      :host     => 'localhost',
      :username => 'root',
      :password => 'rootpass'
    )
    connection
  end
end
