# Default

require 'spec_helper'
require 'socket'

mysql_name = ''
case backend.check_os[:family]
when 'Ubuntu'
  mysql_name = 'mysql'
  mysql_config_file = '/etc/mysql/my.cnf'
  mysql_server_packages = %w{mysql-server apparmor-utils}
  collectd_plugin_dir = '/etc/collectd/plugins'
when 'RedHat'
  mysql_name = 'mysqld'
  mysql_config_file = '/etc/my.cnf'
  mysql_server_packages = %w{mysql-server}
  collectd_plugin_dir = '/etc/collectd.d'
end

describe "MySQL server packages are installed" do
  mysql_server_packages.each do |pkg|
    describe package(pkg) do
      it { should be_installed }
    end
  end
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

describe "verify the tuning attributes set in #{mysql_config_file}" do
  {
    query_cache_size: "4M",
    innodb_buffer_pool_size: "392M",
    thread_cache_size: 50,
    max_connections: 800,
    wait_timeout: 28800,
    net_read_timeout: 30,
    net_write_timeout: 30,
    back_log: 128,
    max_heap_table_size: "32M",
    read_buffer_size: "1M",
    read_rnd_buffer_size: "4M",
    long_query_time: 5,
    key_buffer_size: "16M",
    max_allowed_packet: "20M",
    innodb_log_file_size: "4M",
    innodb_log_buffer_size: "16M",
    table_cache: 256,
    sort_buffer_size: "2M",
    innodb_additional_mem_pool_size: "50M",
    myisam_sort_buffer_size: "64M"
  }.each do |attribute, value|
    describe command("grep -E \"^#{attribute}\\s+\" #{mysql_config_file}") do
      it { should return_stdout /#{value}/ }
    end
  end
end

describe file('/var/lib/mysql') do
  it { should be_directory }
end

describe "can run MySQL queries on the server" do
  describe "'appuser' mysql user is created" do
    describe command(
      "echo \"SELECT User FROM mysql.user\" | mysql --user=root --password=rootpass"
    ) do
      it { should return_stdout /appuser/ }
    end
  end

  describe "'app_test' database exists" do
    describe command(
      "echo \"SHOW DATABASES LIKE 'app_test'\" | mysql --user=appuser --password=apppass"
    ) do
      it { should return_stdout /app_test/ }
    end
  end

  describe "select tables from a database" do
    describe command(
      "echo \"USE app_test; SELECT * FROM app_test\" | mysql --user=appuser --password=apppass"
    ) do
      it { should return_stdout /I am in the db/ }
    end
  end

  describe "create database" do
    describe command(
      "echo \"DROP DATABASE IF EXISTS blah; CREATE DATABASE blah; SHOW DATABASES LIKE 'blah'\" | mysql --user=root --password=rootpass"
    ) do
      it { should return_stdout /blah/ }
    end
  end
end

describe "mysql collectd plugin" do
  describe file("#{collectd_plugin_dir}/mysql.conf") do
    it { should be_file }
  end

  describe "contents of #{collectd_plugin_dir}/mysql.conf" do
    describe command("grep LoadPlugin #{collectd_plugin_dir}/mysql.conf") do
      it { should return_stdout /mysql/ }
    end

    describe command("grep \"^<Plugin\" #{collectd_plugin_dir}/mysql.conf") do
      it { should return_stdout /mysql/ }
    end

    describe command("grep Host #{collectd_plugin_dir}/mysql.conf") do
      it { should return_stdout /localhost/ }
    end

    describe command("grep User #{collectd_plugin_dir}/mysql.conf") do
      it { should return_stdout /root/ }
    end
  end
end

# Verify tags
describe "Default database tags" do
  let(:host_name) { Socket.gethostname.split('.').first }
  let(:default_tags) do
    MachineTag::Set.new(
      JSON.parse(IO.read("/vagrant/cache_dir/machine_tag_cache/#{host_name}/tags.json"))
    )
  end

  it "should have a UUID of 1111111" do
    default_tags['server:uuid'].first.value.should eq('1111111')
  end

  it "should have a public of 10.10.1.1" do
    default_tags['server:public_ip_0'].first.value.should eq('10.10.1.1')
  end

  it "should have a bind port of 3306" do
    default_tags['database:bind_port'].first.value.should eq('3306')
  end

  it "should have a bind IP address of 10.0.2.15" do
    default_tags['database:bind_ip_address'].first.value.should eq('10.0.2.15')
  end

  it "should have 4 database specific entries" do
    default_tags['database'].length.should eq(4)
  end

  it "should be active" do
    default_tags['database:active'].first.value.should be_true
  end

  it "should have a lineage of lineage" do
    default_tags['database:lineage'].first.value.should eq('lineage')
  end
end
