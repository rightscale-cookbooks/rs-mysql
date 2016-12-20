require_relative 'spec_helper'

describe 'rs-mysql::default' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new do |node|
      node.set['cloud']['private_ips'] = ['10.0.2.15']
      node.set['memory']['total'] = '1011228kB'
      node.set['rightscale_volume']['data_storage_1']['device'] = '/dev/sda'
      node.set['rightscale_volume']['data_storage_2']['device'] = '/dev/sdb'
      node.set['rightscale_backup']['data_storage']['devices'] = ['/dev/sda', '/dev/sdb']
      node.set['rs-mysql']['backup']['lineage'] = 'testing'
      node.set['rs-mysql']['server_repl_password'] = 'replpass'
      node.set['rs-mysql']['server_root_password'] = 'rootpass'
      node.set['rs-mysql']['tunable']['innodb_log_file_size'] = '1M'
      node.set['rs-mysql']['application_database_name'] = 'db_test'
    end.converge(described_recipe)
  end
  let(:data_dir) { chef_run.node['mysql']['data_dir'] }

  context 'installing mysql' do
    before(:each) do
      allow(::File).to receive(:exist?).and_call_original
      allow(::File).to receive(:exist?).with("#{data_dir}/ib_logfile0").and_return true
      allow(::File).to receive(:exist?).with("#{data_dir}/mysql_binlogs/mysql-bin.index").and_return true
      allow(::File).to receive(:size).and_call_original
      allow(::File).to receive(:size).with("#{data_dir}/ib_logfile0").and_return 50_331_648
      allow(RsMysql::Tuning).to receive(:megabytes_to_bytes).and_return 1
    end

    it 'stops the mysql service' do
      expect(chef_run).to stop_service('mysql-default')
    end
    it 'deletes old innodb log files' do
      expect(chef_run).to run_execute('delete innodb log files')
    end
    it 'executes update binlog' do
      expect(chef_run).to run_execute('update mysql binlog index with new data_dir')
    end
    it 'installs mysql package' do
      expect(chef_run).to install_package('mysql-server-5.5')
    end
    it 'installs mysql client package' do
      expect(chef_run).to create_mysql_client('default')
    end
    it 'starts the mysql service' do
      expect(chef_run).to start_mysql_service('default')
    end
    it 'creates the binlog dir' do
      expect(chef_run).to create_directory("#{data_dir}/mysql_binlogs")
    end
    it 'creates the mysql config' do
      expect(chef_run).to create_mysql_config('default')
    end
    it 'creates the my.cnf link' do
      expect(chef_run).to create_link('/etc/my.cnf')
    end
    it 'installs the mysql2 chef gem' do
      expect(chef_run).to install_mysql2_chef_gem('default')
    end
    it 'waits for chef to be awake' do
      expect(chef_run).to run_ruby_block('wait for listening')
    end
    it 'creates the database tags' do
      expect(chef_run).to create_rightscale_tag_database('testing')
    end
    it 'creates the app db' do
      expect(chef_run).to create_mysql_database('application database')
    end
  end
end
