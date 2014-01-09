require 'spec_helper'
require 'tuning'

describe RsMysql::Tuning do
  [
    ['dedicated', 1],
    ['shared', 0.5],
  ].each do |usage, factor|
    context "with #{usage} usage" do
      [
        {
          name: '512 MB',
          memory: '524288kB',
          assertions: {
            key_buffer: "#{(16 * factor).to_i}M",
            max_allowed_packet: "#{(20 * factor).to_i}M",
            innodb_log_file_size: "#{(4 * factor).to_i}M",
            innodb_log_buffer_size: "#{(16 * factor).to_i}M",
            table_cache: (256 * factor).to_i,
            sort_buffer_size: "#{(2 * factor).to_i}M",
            innodb_additional_mem_pool_size: "#{(50 * factor).to_i}M",
            myisam_sort_buffer_size: "#{(64 * factor).to_i}M",
          },
        },
        {
          name: '512 MB (in bytes)',
          memory: 536870912,
          assertions: {
            key_buffer: "#{(16 * factor).to_i}M",
            max_allowed_packet: "#{(20 * factor).to_i}M",
            innodb_log_file_size: "#{(4 * factor).to_i}M",
            innodb_log_buffer_size: "#{(16 * factor).to_i}M",
            table_cache: (256 * factor).to_i,
            sort_buffer_size: "#{(2 * factor).to_i}M",
            innodb_additional_mem_pool_size: "#{(50 * factor).to_i}M",
            myisam_sort_buffer_size: "#{(64 * factor).to_i}M",
          },
        },
        {
          name: '2 GB',
          memory: '2097152kB',
          assertions: {
            key_buffer: "#{(128 * factor).to_i}M",
            max_allowed_packet: "#{(128 * factor).to_i}M",
            innodb_log_file_size: "#{(64 * factor).to_i}M",
            innodb_log_buffer_size: "#{(8 * factor).to_i}M",
            table_cache: (256 * factor).to_i,
            sort_buffer_size: "#{(2 * factor).to_i}M",
            innodb_additional_mem_pool_size: "#{(50 * factor).to_i}M",
            myisam_sort_buffer_size: "#{(64 * factor).to_i}M",
          },
        },
        {
          name: '5 GB',
          memory: '5242880kB',
          assertions: {
            key_buffer: "#{(128 * factor).to_i}M",
            max_allowed_packet: "#{(128 * factor).to_i}M",
            innodb_log_file_size: "#{(64 * factor).to_i}M",
            innodb_log_buffer_size: "#{(8 * factor).to_i}M",
            table_cache: (512 * factor).to_i,
            sort_buffer_size: "#{(4 * factor).to_i}M",
            innodb_additional_mem_pool_size: "#{(200 * factor).to_i}M",
            myisam_sort_buffer_size: "#{(96 * factor).to_i}M",
          },
        },
        {
          name: '15 GB',
          memory: '15728640kB',
          assertions: {
            key_buffer: "#{(128 * factor).to_i}M",
            max_allowed_packet: "#{(128 * factor).to_i}M",
            innodb_log_file_size: "#{(64 * factor).to_i}M",
            innodb_log_buffer_size: "#{(8 * factor).to_i}M",
            table_cache: (1024 * factor).to_i,
            sort_buffer_size: "#{(8 * factor).to_i}M",
            innodb_additional_mem_pool_size: "#{(300 * factor).to_i}M",
            myisam_sort_buffer_size: "#{(128 * factor).to_i}M",
          },
        },
        {
          name: '30 GB',
          memory: '31457280kB',
          assertions: {
            key_buffer: "#{(128 * factor).to_i}M",
            max_allowed_packet: "#{(128 * factor).to_i}M",
            innodb_log_file_size: "#{(64 * factor).to_i}M",
            innodb_log_buffer_size: "#{(8 * factor).to_i}M",
            table_cache: (2048 * factor).to_i,
            sort_buffer_size: "#{(16 * factor).to_i}M",
            innodb_additional_mem_pool_size: "#{(400 * factor).to_i}M",
            myisam_sort_buffer_size: "#{(256 * factor).to_i}M",
          },
        },
        {
          name: '55 GB',
          memory: '57671680kB',
          assertions: {
            key_buffer: "#{(128 * factor).to_i}M",
            max_allowed_packet: "#{(128 * factor).to_i}M",
            innodb_log_file_size: "#{(64 * factor).to_i}M",
            innodb_log_buffer_size: "#{(8 * factor).to_i}M",
            table_cache: (4096 * factor).to_i,
            sort_buffer_size: "#{(32 * factor).to_i}M",
            innodb_additional_mem_pool_size: "#{(500 * factor).to_i}M",
            myisam_sort_buffer_size: "#{(512 * factor).to_i}M",
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

          let(:tune_attributes) do
            described_class.tune_attributes(
              node.override['mysql']['tunable'],
              node['memory']['total'],
              usage
            )
          end

          category[:assertions].each do |name, value|
            it "sets #{name} to #{value}" do
              tune_attributes
              node['mysql']['tunable'][name].should eq(value)
            end
          end
        end
      end
    end
  end
end
