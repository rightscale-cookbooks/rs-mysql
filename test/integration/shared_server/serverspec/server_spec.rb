# Shared Server

require 'spec_helper'

case os[:family]
when 'ubuntu'
  mysql_config_file = '/etc/mysql/my.cnf'
when 'redhat'
  mysql_config_file = '/etc/my.cnf'
end

describe "verify the tuning attributes set in #{mysql_config_file}" do
  {
    query_cache_size:"2M",
    innodb_buffer_pool_size: "19[56]M",
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
      its(:stdout) { should match /#{value}/ }
    end
  end
end
