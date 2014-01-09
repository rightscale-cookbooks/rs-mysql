require 'spec_helper'
require 'tuning'

describe RsMysql::Tuning do
  [
    {
      name: '512 MB',
      memory: '524288kB',
      assertions: {
        key_buffer: '16M',
        max_allowed_packet: '20M',
        innodb_log_file_size: '4M',
        innodb_log_buffer_size: '16M',
        table_cache: 256,
        sort_buffer_size: '2M',
        innodb_additional_mem_pool_size: '50M',
        myisam_sort_buffer_size: '64M',
      },
    },
    {
      name: '512 MB (in bytes)',
      memory: 536870912,
      assertions: {
        key_buffer: '16M',
        max_allowed_packet: '20M',
        innodb_log_file_size: '4M',
        innodb_log_buffer_size: '16M',
        table_cache: 256,
        sort_buffer_size: '2M',
        innodb_additional_mem_pool_size: '50M',
        myisam_sort_buffer_size: '64M',
      },
    },
    {
      name: '2 GB',
      memory: '2097152kB',
      assertions: {
        key_buffer: '128M',
        max_allowed_packet: '128M',
        innodb_log_file_size: '64M',
        innodb_log_buffer_size: '8M',
        table_cache: 256,
        sort_buffer_size: '2M',
        innodb_additional_mem_pool_size: '50M',
        myisam_sort_buffer_size: '64M',
      },
    },
    {
      name: '5 GB',
      memory: '5242880kB',
      assertions: {
        key_buffer: '128M',
        max_allowed_packet: '128M',
        innodb_log_file_size: '64M',
        innodb_log_buffer_size: '8M',
        table_cache: 512,
        sort_buffer_size: '4M',
        innodb_additional_mem_pool_size: '200M',
        myisam_sort_buffer_size: '96M',
      },
    },
    {
      name: '15 GB',
      memory: '15728640kB',
      assertions: {
        key_buffer: '128M',
        max_allowed_packet: '128M',
        innodb_log_file_size: '64M',
        innodb_log_buffer_size: '8M',
        table_cache: 1024,
        sort_buffer_size: '8M',
        innodb_additional_mem_pool_size: '300M',
        myisam_sort_buffer_size: '128M',
      },
    },
    {
      name: '30 GB',
      memory: '31457280kB',
      assertions: {
        key_buffer: '128M',
        max_allowed_packet: '128M',
        innodb_log_file_size: '64M',
        innodb_log_buffer_size: '8M',
        table_cache: 2048,
        sort_buffer_size: '16M',
        innodb_additional_mem_pool_size: '400M',
        myisam_sort_buffer_size: '256M',
      },
    },
    {
      name: '55 GB',
      memory: '57671680kB',
      assertions: {
        key_buffer: '128M',
        max_allowed_packet: '128M',
        innodb_log_file_size: '64M',
        innodb_log_buffer_size: '8M',
        table_cache: 4096,
        sort_buffer_size: '32M',
        innodb_additional_mem_pool_size: '500M',
        myisam_sort_buffer_size: '512M',
      },
    },
  ].each do |category|
    context "with #{category[:name]} of memory" do
      let(:node) do
        chef_run = ChefSpec::Runner.new do |node|
          node.set['memory']['total'] = category[:memory]
        end
        chef_run.node
      end

      let(:tuning_attributes) do
        described_class.calculate_mysql_tuning_attributes(
          node.override['mysql']['tunable'],
          node['memory']['total'],
          'dedicated'
        )
      end

      category[:assertions].each do |name, value|
        it "sets #{name} to #{value}" do
          tuning_attributes
          node['mysql']['tunable'][name].should eq(value)
        end
      end
    end
  end
end
