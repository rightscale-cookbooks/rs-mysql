# Slave

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

describe "MySQL server" do
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

describe "Verify the parameters directly from msyql" do
  {
    log_bin: 1,
    read_only: 1,
    binlog_format: "MIXED",
    expire_logs_days: 10
  }.each do |attribute, value|
    it "parameter #{attribute} should return #{value}" do
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

describe "Check slave status" do
  describe "Master_Host matches 173.227.0.5" do
    describe command(
      "echo \"SHOW SLAVE STATUS \\G \" | mysql --user=root --password=rootpass"
    ) do
      it { should return_stdout /Master_Host: 173.227.0.5/ }
    end
  end

  describe "Master_Port matches 3306" do
    describe command(
      "echo \"SHOW SLAVE STATUS \\G \" | mysql --user=root --password=rootpass"
    ) do
      it { should return_stdout /Master_Port: 3306/ }
    end
  end

end

# Verify tags
describe "Slave database tags" do
  let(:host_name) { Socket.gethostname }
  let(:slave_tags) { MachineTag::Set.new(JSON.parse(IO.read("/vagrant/cache_dir/machine_tag_cache/#{host_name}/tags.json"))) }

  it "should have a UUID of 2222222" do
    slave_tags['server:uuid'].first.value.should match ('2222222')
  end

  it "should have a public of 10.10.2.2" do
    slave_tags['server:public_ip_0'].first.value.should match ('10.10.2.2')
  end

  it "should have a private ip address of 10.10.3.3" do
    slave_tags['server:private_ip_0'].first.value.should match ('10.10.3.3')
  end

  it "should have a bind port of 3306" do
    slave_tags['database:bind_port'].first.value.should match ('3306')
  end

  it "should have 5 database specific entries" do
    slave_tags['database'].length.should == 5
  end

  it "should be active" do
    slave_tags['database:active'].first.value.should be_true
  end

  it "should have a lineage of lineage" do
    slave_tags['database:lineage'].first.value.should match ('lineage')
  end

  # We want to test that the slave_active timestamp is a reasonable value; arbitrarily within the last 24 hours
  let(:db_time) { Time.at(slave_tags['database:slave_active'].first.value.to_i) }

  it "should have a slave_active value that is valid (within the last 24 hours)" do
    (Time.now - db_time).should < 86400
  end
end
