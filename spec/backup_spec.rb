# frozen_string_literal: true
require_relative 'spec_helper'
require 'mysql2'

describe 'rs-mysql::backup' do
  cached(:chef_run) do
    ChefSpec::SoloRunner.new do |node|
      node.set['chef_handler']['handler_path'] = '/var/chef/handlers'
      node.set['rs-mysql']['server_root_password'] = 'rootpass'
      node.set['rs-mysql']['backup']['lineage'] = 'testing'
    end.converge(described_recipe)
  end
  let(:nickname) { chef_run.node['rs-mysql']['device']['nickname'] }
  let(:mysql_master_info_json) do
    <<-EOF.gsub('    ', '').chomp
    {
      "file": "mysql-bin.000012",
      "position": "394"
    }
    EOF
  end

  before do
    connection = double
    master_status = double
    slave_status = double
    # Mysql.stub(:new).with('localhost', 'root', 'rootpass').and_return(connection)
    Mysql2::Client.stub(:new).with(host: 'localhost', username: 'root', password: 'rootpass', default_file: '/etc/mysql-default/my.cnf').and_return(connection)
    allow(connection).to receive(:query).with('SHOW MASTER STATUS', as: :hash, symbolize_keys: false).and_return(master_status)
    allow(connection).to receive(:query).with('SHOW SLAVE STATUS', as: :hash, symbolize_keys: false).and_return(slave_status)
    allow(connection).to receive(:close)
    allow(master_status).to receive(:first).and_return('File' => 'mysql-bin.000012',
                                                       'Position' => '394',
                                                       'Binlog_Do_DB' => '',
                                                       'Binlog_Ignore' => '')
    allow(slave_status).to receive(:first).and_return(nil)
  end

  it 'sets up chef error handler' do
    expect(chef_run).to include_recipe('chef_handler::default')
    expect(chef_run).to create_cookbook_file('/var/chef/handlers/rs-mysql_backup.rb').with(
      source: 'backup_error_handler.rb'
    )
    expect(chef_run).to enable_chef_handler('Rightscale::BackupErrorHandler').with(
      source: '/var/chef/handlers/rs-mysql_backup.rb'
    )
  end

  it 'locks the database' do
    expect(chef_run).to query_mysql_database('flush tables with read lock').with(
      database_name: 'mysql',
      sql: 'FLUSH TABLES WITH READ LOCK'
    )
  end

  it 'writes the master info JSON file' do
    expect(chef_run).to create_file('generate master info JSON file').with(
      content: mysql_master_info_json,
      path: '/mnt/storage/mysql_master_info.json'
    )
  end

  it 'freezes the filesystem' do
    expect(chef_run).to write_log('Freezing the filesystem mounted on /mnt/storage')
    expect(chef_run).to freeze_filesystem("freeze #{nickname}").with(
      label: nickname,
      mount: '/mnt/storage'
    )
  end

  it 'creates a backup' do
    expect(chef_run).to write_log('Taking a backup of lineage \'testing\'')
    expect(chef_run).to create_rightscale_backup(nickname).with(
      lineage: 'testing'
    )
  end

  it 'unfreezes the filesystem' do
    expect(chef_run).to write_log('Unfreezing the filesystem mounted on /mnt/storage')
    expect(chef_run).to unfreeze_filesystem("unfreeze #{nickname}").with(
      label: nickname,
      mount: '/mnt/storage'
    )
  end

  it 'deletes the master info JSON file' do
    expect(chef_run).to delete_file('delete master info JSON file').with(
      path: '/mnt/storage/mysql_master_info.json'
    )
  end

  it 'unlocks the database' do
    expect(chef_run).to query_mysql_database('unlock tables').with(
      database_name: 'mysql',
      sql: 'UNLOCK TABLES'
    )
  end

  it 'cleans up old backups' do
    expect(chef_run).to write_log('Cleaning up old snapshots')
    expect(chef_run).to cleanup_rightscale_backup(nickname).with(
      lineage: 'testing',
      keep_last: 60,
      dailies: 14,
      weeklies: 6,
      monthlies: 12,
      yearlies: 2
    )
  end
end
