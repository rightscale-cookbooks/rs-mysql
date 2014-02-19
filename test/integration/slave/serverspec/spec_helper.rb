require 'serverspec'
require 'pathname'
require 'json'
require 'rubygems/dependency_installer'

include Serverspec::Helper::Exec
include Serverspec::Helper::DetectOS

installer = Gem::DependencyInstaller.new
installer.install('mysql2')
Gem.clear_paths

installer = Gem::DependencyInstaller.new
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

def close
  @db.close rescue nil
  @db = nil
end
