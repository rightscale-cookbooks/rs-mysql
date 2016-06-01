require_relative 'spec_helper'

describe 'rs-mysql::schedule' do
  context 'rs-mysql/schedule/enable is true' do
    let(:chef_run) do
      ChefSpec::Runner.new do |node|
        node.set['rs-mysql']['schedule']['enable'] = true
        node.set['rs-mysql']['backup']['lineage'] = 'testing'
        node.set['rs-mysql']['schedule']['hour'] = '10'
        node.set['rs-mysql']['schedule']['minute'] = '30'
      end.converge(described_recipe)
    end
    let(:lineage) { chef_run.node['rs-mysql']['backup']['lineage'] }

    it 'creates a crontab entry' do
      expect(chef_run).to create_cron("backup_schedule_#{lineage}").with(
        minute: chef_run.node['rs-mysql']['schedule']['minute'],
        hour: chef_run.node['rs-mysql']['schedule']['hour'],
        command: "sudo rsc rl10 run_right_script /rll/run/right_script 'right_script=Mysql Server Backup - chef'"
      )
    end
  end

  context 'rs-mysql/schedule/enable is false' do
    let(:chef_run) do
      ChefSpec::Runner.new do |node|
        node.set['rs-mysql']['schedule']['enable'] = false
        node.set['rs-mysql']['backup']['lineage'] = 'testing'
      end.converge(described_recipe)
    end
    let(:lineage) { chef_run.node['rs-mysql']['backup']['lineage'] }

    it 'deletes a crontab entry' do
      expect(chef_run).to delete_cron("backup_schedule_#{lineage}").with(
        command: "sudo rsc rl10 run_right_script /rll/run/right_script 'right_script=Mysql Server Backup - chef'"
      )
    end
  end

  context 'rs-mysql/schedule/hour or rs-mysql/schedule/minute missing' do
    let(:chef_run) do
      ChefSpec::Runner.new do |node|
        node.set['rs-mysql']['backup']['lineage'] = 'testing'
        node.set['rs-mysql']['schedule']['enable'] = true
        node.set['rs-mysql']['schedule']['hour'] = '10'
      end.converge(described_recipe)
    end
    let(:lineage) { chef_run.node['rs-mysql']['backup']['lineage'] }

    it 'raises an error' do
      expect { chef_run }.to raise_error(
        RuntimeError,
        'rs-mysql/schedule/hour and rs-mysql/schedule/minute inputs should be set'
      )
    end
  end
end
