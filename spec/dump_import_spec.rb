require_relative 'spec_helper'

describe 'rs-mysql::dump_import' do
  context 'rs-mysql/import/private_key is NOT set' do
    let(:chef_run) do
      ChefSpec::Runner.new do |node|
        node.set['cloud']['private_ips'] = ['10.0.2.15']
        node.set['memory']['total'] = '1011228kB'
        node.set['rs-mysql']['application_database_name'] = 'apptest'
        node.set['rs-mysql']['backup']['lineage'] = 'testing'
        node.set['rs-mysql']['server_repl_password'] = 'replpass'
        node.set['rs-mysql']['server_root_password'] = 'rootpass'
        node.set['rs-mysql']['import']['repository'] = 'https://github.com/rightscale/examples.git'
        node.set['rs-mysql']['import']['revision'] = 'unified_php'
        node.set['rs-mysql']['import']['dump_file'] = 'app_test.sql.bz2'
        node.set['rs-mysql']['import']['private_key'] = nil
      end.converge(described_recipe)
    end

    it 'installs git' do
      expect(chef_run).to include_recipe('git')
    end
  end

  context 'rs-mysql/import/private_key is set' do
    let(:chef_run) do
      ChefSpec::Runner.new do |node|
        node.set['rs-mysql']['import']['private_key'] = "private_key_data"
      end.converge(described_recipe)
    end

    it 'installs git' do
      expect(chef_run).to include_recipe('git')
    end
  end

end
