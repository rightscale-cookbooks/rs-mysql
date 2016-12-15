require_relative 'spec_helper'

describe 'rs-mysql::default' do
  before do
    stub_command("/usr/bin/mysql -u root -e 'show databases;'").and_return(true)
  end

  let(:chef_run) do
    ChefSpec::SoloRunner.new do |node|
      node.set['cloud']['public_ips'] = ['', '10.1.1.1']
      node.set['cloud']['private_ips'] = ['10.0.2.15', '10.0.2.16']
      node.set['memory']['total'] = '1011228kB'
      node.set['rs-mysql']['application_database_name'] = 'apptest'
      node.set['rs-mysql']['backup']['lineage'] = 'testing'
      node.set['rs-mysql']['server_repl_password'] = 'replpass'
      node.set['rs-mysql']['server_root_password'] = 'rootpass'
    end.converge(described_recipe)

    # Chefspec by default sets node['macaddress'] to '11:11:11:11:11:11'
    # In generating the server_id, we remove the first 2 octets - we do the same here to verify
    it 'sets server_id based on macaddress' do
      expect(chef_run.node['mysql']['tunable']['server_id']).to eq(0x11111111)
    end
  end
end
