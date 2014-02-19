require 'spec_helper'

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

describe "Verify the parameters directly from msyql" do
  {
    log_bin: 1,
    read_only: 0,
    binlog_format: "MIXED",
    expire_logs_days: 10
  }.each do |attribute, value|
    it "paremeter #{attribute} should return #{value}" do
      db.query("select @@global.#{attribute}").entries.first["@@global.#{attribute}"].should  == value
    end
  end
end

describe "Verify replication setup:" do
   it "User repl should be created." do
     db.query("select distinct user from mysql.user").entries.count { |u| u['user'] == 'repl' }.should == 1
   end
   it "repl user should have replication privileges." do
     db.query("show grants for 'repl'").entries.first['Grants for repl@%'].should =~ /^GRANT REPLICATION SLAVE ON \*\.\* TO \'repl\'/
   end
end

describe "Verify master status" do
   it "Master should have entry mysql-bin file" do
     db.query("show master status").entries[0]['File'].should =~ /^mysql-bin/
   end
   it "with a non-zero position marker" do
     db.query("show master status").entries[0]['Position'].should_not == 0
   end
end

# The kitchen.yml file is set up to provide a public ip in the master suite.   This is what this is testing.
# The slave setup will provide a null public, and a private ip.
describe "Verify valid server-id entry" do
   it "should correspond to the result of IPAddr converting 173.227.0.5 to an integer" do
     db.query("show variables like 'server_id'").entries.first['Value'].to_i.should == 2917335045
   end
end

# Verify tags

# Get the hostname
host_name = `hostname -s`.chomp

master_tags = MachineTag::Set.new(JSON.parse(IO.read("/vagrant/cache_dir/machine_tag_cache/#{host_name}/tags.json")))

describe "Master database tags" do
  it "should have a UUID of 1111111" do
    master_tags['server:uuid'].first.value.should match ('1111111')
  end
  it "should have a public of 173.227.0.5" do
    master_tags['server:public_ip_0'].first.value.should match ('173.227.0.5')
  end
  it "should have a bind ip address of 10.0.2.15" do
    master_tags['database:bind_ip_address'].first.value.should match ('10.0.2.15')
  end
  it "should have a bind port of 3306" do
    master_tags['database:bind_port'].first.value.should match ('3306')
  end
  it "should have 5 database specific entries" do
    master_tags['database'].length.should == 5
  end
  it "should be active" do
    master_tags['database:active'].first.value.should be_true
  end
  it "should have a lineage of lineage" do
    master_tags['database:lineage'].first.value.should match ('lineage')
  end
  it "should have a master active value of 1392834749" do
    master_tags['database:master_active'].first.value.should match ('1392834749')
  end
end

end
