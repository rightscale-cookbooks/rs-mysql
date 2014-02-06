require 'serverspec'
require 'pathname'
require 'rubygems/dependency_installer'

include Serverspec::Helper::Exec
include Serverspec::Helper::DetectOS

installer = Gem::DependencyInstaller.new
installer.install('mysql')
Gem.clear_paths

require 'mysql'

def db
  @db ||= begin
    connection = ::Mysql.new(
      'localhost',
      'root',
      'rootpass',
      nil,
      3306,
      nil
    )
    connection.set_server_option ::Mysql::OPTION_MULTI_STATEMENTS_ON
    connection
  end
end

def close
  @db.close rescue nil
  @db = nil
end
