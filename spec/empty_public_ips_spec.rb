require_relative 'spec_helper'

describe 'rs-mysql::default' do

  before do
    stub_command("/usr/bin/mysql -u root -e 'show databases;'").and_return(true)
  end

  context 'cloud/public_ips has blank first entry' do
    let(:chef_run) do
      ChefSpec::Runner.new do |node|
        node.set['cloud']['public_ips'] = ['', '10.1.1.1']
        node.set['cloud']['private_ips'] = ['10.0.2.15', '10.0.2.16']
        node.set['memory']['total'] = '1011228kB'
        node.set['rs-mysql']['application_database_name'] = 'apptest'
        node.set['rs-mysql']['backup']['lineage'] = 'testing'
        node.set['rs-mysql']['server_repl_password'] = 'replpass'
        node.set['rs-mysql']['server_root_password'] = 'rootpass'
      end.converge(described_recipe)
    end

    it 'skips blank entry in public_ips' do
      expect(chef_run.node['mysql']['tunable']['server_id']).to eq(IPAddr.new('10.1.1.1').to_i)
    end
  end

  context 'cloud/public_ips has no valid entry' do
    let(:chef_run) do
      ChefSpec::Runner.new do |node|
        node.set['cloud']['public_ips'] = ['', '']
        node.set['cloud']['private_ips'] = ['10.0.2.15', '10.0.2.16']
        node.set['memory']['total'] = '1011228kB'
        node.set['rs-mysql']['application_database_name'] = 'apptest'
        node.set['rs-mysql']['backup']['lineage'] = 'testing'
        node.set['rs-mysql']['server_repl_password'] = 'replpass'
        node.set['rs-mysql']['server_root_password'] = 'rootpass'
      end.converge(described_recipe)
    end

    it 'skips blank entry in public_ips' do
      expect(chef_run.node['mysql']['tunable']['server_id']).to eq(IPAddr.new('10.0.2.15').to_i)
    end
  end
end
