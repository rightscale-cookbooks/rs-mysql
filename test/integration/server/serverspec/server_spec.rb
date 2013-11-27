require 'spec_helper'

mysql_name = ''
case backend.check_os[:family]
when 'Debian'
  mysql_name = 'mysql'
  mysql_config_file = '/etc/mysql/my.cnf'
when 'RedHat'
  mysql_name = 'mysqld'
  mysql_config_file = '/etc/my.cnf'
end

describe package('mysql-server') do
  it { should be_installed }
end

describe service(mysql_name) do
  it { should be_enabled }
  it { should be_running }
end

describe port(3306) do
  it { should be_listening }
end

describe file(mysql_config_file) do
  it { should be_file }
end

describe file('/var/lib/mysql') do
  it { should be_directory }
end
