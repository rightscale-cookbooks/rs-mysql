require 'serverspec'
require 'pathname'
require 'rubygems/dependency_installer'

include Serverspec::Helper::Exec
include Serverspec::Helper::DetectOS

installer = Gem::DependencyInstaller.new
installer.install('mysql2')
Gem.clear_paths

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
