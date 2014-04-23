require_relative 'spec_helper'

describe 'rs-mysql::backup' do
  let(:chef_run) do
    ChefSpec::Runner.new do |node|
      node.set['rs-mysql']['backup']['lineage'] = 'testing'
    end.converge(described_recipe)
  end
  let(:nickname) { chef_run.node['rs-mysql']['device']['nickname'] }

  it 'sets up chef error handler' do
    expect(chef_run).to include_recipe('chef_handler::default')
    expect(chef_run).to create_cookbook_file('/var/chef/handlers/rs-mysql_backup.rb').with(
      source: 'backup_error_handler.rb',
    )
    expect(chef_run).to enable_chef_handler('Rightscale::BackupErrorHandler').with(
      source: '/var/chef/handlers/rs-mysql_backup.rb',
    )
  end

  it 'locks the database' do
    expect(chef_run).to query_mysql_database('flush tables with read lock').with(
      database_name: 'mysql',
      sql: 'FLUSH TABLES WITH READ LOCK',
    )
  end

  it 'freezes the filesystem' do
    expect(chef_run).to freeze_filesystem("freeze #{nickname}").with(
      label: nickname,
      mount: '/mnt/storage',
    )
  end

  it 'creates a backup' do
    expect(chef_run).to create_rightscale_backup(nickname).with(
      lineage: 'testing',
    )
  end

  it 'unfreezes the filesystem' do
    expect(chef_run).to unfreeze_filesystem("unfreeze #{nickname}").with(
      label: nickname,
      mount: '/mnt/storage',
    )
  end

  it 'unlocks the database' do
    expect(chef_run).to query_mysql_database('unlock tables').with(
      database_name: 'mysql',
      sql: 'UNLOCK TABLES',
    )
  end

  it 'cleans up old backups' do
    expect(chef_run).to cleanup_rightscale_backup(nickname).with(
      lineage: 'testing',
      keep_last: 60,
      dailies: 14,
      weeklies: 6,
      monthlies: 12,
      yearlies: 2,
    )
  end
end
