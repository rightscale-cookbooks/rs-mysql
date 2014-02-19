require 'spec_helper'

case backend.check_os[:family]
when 'Ubuntu'
  mysql_config_file = '/etc/mysql/my.cnf'
when 'RedHat'
  mysql_config_file = '/etc/my.cnf'
end

describe "verify the tuning attributes set in #{mysql_config_file}" do
  {
    query_cache_size:"2M",
    innodb_buffer_pool_size: "196M",
    thread_cache_size: 25,
    max_connections: 400,
    wait_timeout: 14400,
    net_read_timeout: 15,
    net_write_timeout: 15,
    back_log: 64,
    max_heap_table_size: "16M",
    read_buffer_size: "0M",
    read_rnd_buffer_size: "2M",
    long_query_time: 5,
    key_buffer_size: "8M",
    max_allowed_packet: "10M",
    innodb_log_file_size: "2M",
    innodb_log_buffer_size: "8M",
    table_cache: 128,
    sort_buffer_size: "1M",
    innodb_additional_mem_pool_size: "25M",
    myisam_sort_buffer_size: "32M"
  }.each do |attribute, value|
    describe command("grep -E \"^#{attribute}\\s+\" #{mysql_config_file}") do
      it { should return_stdout /#{value}/ }
    end
  end
end

# Verify tags

# Get the hostname
host_name = `hostname -s`.chomp

shared_server_tags = MachineTag::Set.new(JSON.parse(IO.read("/vagrant/cache_dir/machine_tag_cache/#{host_name}/tags.json")))

describe "Shared server database tags" do
  it "should have a public of 10.10.0.0" do
    shared_server_tags['server:public_ip_0'].first.value.should match ('10.10.0.0')
  end
  it "should have a bind port of 3306" do
    shared_server_tags['database:bind_port'].first.value.should match ('3306')
  end
  it "should have a bind IP address of 10.0.2.15" do
    shared_server_tags['database:bind_ip_address'].first.value.should match ('10.0.2.15')
  end
  it "should have 4 database specific entries" do
    shared_server_tags['database'].length.should == 4
  end
  it "should be active" do
    shared_server_tags['database:active'].first.value.should be_true
  end
  it "should have a lineage of lineage" do
    shared_server_tags['database:lineage'].first.value.should match ('lineage')
  end
end
