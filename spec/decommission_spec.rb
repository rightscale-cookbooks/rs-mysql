require_relative 'spec_helper'

describe 'rs-mysql::decommission' do
  let(:chef_runner) do
    ChefSpec::SoloRunner.new do |node|
      node.set['cloud']['private_ips'] = ['10.0.2.15']
      node.set['memory']['total'] = '1011228kB'
      node.set['rs-mysql']['application_database_name'] = 'apptest'
      node.set['rs-mysql']['backup']['lineage'] = 'testing'
      node.set['rs-mysql']['server_repl_password'] = 'replpass'
      node.set['rs-mysql']['server_root_password'] = 'rootpass'
    end
  end

  context 'rs-mysql/device/destroy_on_decommission is set to false' do
    let(:chef_run) do
      chef_runner.converge(described_recipe)
    end

    it 'logs that it is skipping destruction' do
      expect(chef_run).to write_log("rs-mysql/device/destroy_on_decommission is set to 'false' skipping...")
    end
  end

  context 'rs-mysql/device/destroy_on_decommission is set to true' do
    let(:chef_runner_decommission) do
      chef_runner.node.set['rs-mysql']['device']['destroy_on_decommission'] = true
      chef_runner.node.set['rightscale']['decom_reason'] = 'terminate'
      chef_runner
    end
    let(:nickname) { chef_runner.converge(described_recipe).node['rs-mysql']['device']['nickname'] }

    context 'RightScale run state is terminate' do
      before do
        stub_command('test -L /var/lib/mysql-default').and_return(true)
        stub_command('[ `stat -c %h /var/lib/mysql-default/` -eq 2 ]').and_return(true)
        stub_command('test -d /mnt/storage/mysql').and_return(true)
        stub_command('test -f /var/lib/mysql/ib_logfile0').and_return(true)
      end

      context 'LVM is not used' do
        before do
          output = '/dev/sda on /mnt/storage type ext4 (auto)'
          mount = double(run_command: nil, error!: nil, stdout: output, stderr: double(empty?: true), exitstatus: 0, live_stream: nil, 'live_stream=' => nil, status: 0)
          allow(Mixlib::ShellOut).to receive(:new).and_return(mount)
        end

        let(:chef_run) do
          chef_runner_decommission.node.set['rightscale_volume'][nickname]['device'] = '/dev/sda'
          chef_runner_decommission.converge(described_recipe)
        end

        it 'removes /var/lib/mysql-default symlink' do
          expect(chef_run).to delete_link('/var/lib/mysql-default')
        end

        it 'unmounts and disables the volume on the instance' do
          expect(chef_run).to umount_mount('/mnt/storage').with(
            device: '/dev/sda'
          )
          expect(chef_run).to disable_mount('/mnt/storage')
        end

        it 'detaches the volume from the instance' do
          expect(chef_run).to detach_rightscale_volume(nickname)
        end

        it 'deletes the volume from the cloud' do
          expect(chef_run).to delete_rightscale_volume(nickname)
        end

        it 'deletes tags for master and slave roles from the instance' do
          expect(chef_run).to delete_rightscale_tag_database('master testing').with(
            role: 'master',
            lineage: 'testing',
            bind_ip_address: '10.0.2.15',
            bind_port: 3306
          )
          expect(chef_run).to delete_rightscale_tag_database('slave testing').with(
            role: 'slave',
            lineage: 'testing',
            bind_ip_address: '10.0.2.15',
            bind_port: 3306
          )
        end
      end

      context 'LVM is used' do
        before do
          output = '/dev/mapper/vol-group--logical-volume-1 on /mnt/storage type ext4 (auto)'
          mount = double(run_command: nil, error!: nil, stdout: output, stderr: double(empty?: true), exitstatus: 0, live_stream: nil, 'live_stream=' => nil, status: 0)
          allow(Mixlib::ShellOut).to receive(:new).and_return(mount)

          lvdisplay = double(run_command: nil, error!: nil, stdout: output, stderr: double(empty?: true), exitstatus: 0, live_stream: nil, 'live_stream=' => nil, status: 0)
          allow(Mixlib::ShellOut).to receive(:new).and_return(lvdisplay)
        end

        let(:chef_run) do
          chef_runner_decommission.node.set['rs-mysql']['device']['count'] = 2
          chef_runner_decommission.converge(described_recipe)
        end
        let(:logical_volume_device) do
          "/dev/mapper/#{nickname.gsub('_', '--')}--vg-#{nickname.gsub('_', '--')}--lv"
        end

        it 'removes /var/lib/mysql-default symlink' do
          expect(chef_run).to delete_link('/var/lib/mysql-default')
        end

        it 'unmounts and disables the volume on the instance' do
          expect(chef_run).to umount_mount('/mnt/storage').with(
            device: logical_volume_device
          )
          expect(chef_run).to disable_mount('/mnt/storage')
        end

        it 'cleans up the LVM' do
          expect(chef_run).to run_ruby_block('clean up LVM')
        end

        it 'detaches the volumes from the instance' do
          expect(chef_run).to detach_rightscale_volume("#{nickname}_1")
          expect(chef_run).to detach_rightscale_volume("#{nickname}_2")
        end

        it 'deletes the volumes from the cloud' do
          expect(chef_run).to delete_rightscale_volume("#{nickname}_1")
          expect(chef_run).to delete_rightscale_volume("#{nickname}_2")
        end

        it 'deletes tags for master and slave roles from the instance' do
          expect(chef_run).to delete_rightscale_tag_database('master testing').with(
            role: 'master',
            lineage: 'testing',
            bind_ip_address: '10.0.2.15',
            bind_port: 3306
          )
          expect(chef_run).to delete_rightscale_tag_database('slave testing').with(
            role: 'slave',
            lineage: 'testing',
            bind_ip_address: '10.0.2.15',
            bind_port: 3306
          )
        end
      end
    end

    %w(reboot stop).each do |state|
      context "RightScale run state is #{state}" do
        let(:chef_run) do
          chef_runner_decommission.node.set['rightscale']['decom_reason'] = state
          chef_runner_decommission.converge(described_recipe)
        end

        it 'logs that it is skipping destruction' do
          expect(chef_run).to write_log('Skipping deletion of volumes as the instance is either rebooting or entering the stop state...')
        end
      end
    end
  end
end
