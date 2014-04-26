#
# Cookbook Name:: rs-mysql
# Recipe:: decommission
#
# Copyright (C) 2014 RightScale, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

marker "recipe_start_rightscale" do
  template "rightscale_audit_entry.erb"
end

# Check for the safety attribute first
if node['rs-mysql']['device']['destroy_on_decommission'] != true &&
  node['rs-mysql']['device']['destroy_on_decommission'] != 'true'
  log "rs-mysql/device/destroy_on_decommission is set to '#{node['rs-mysql']['device']['destroy_on_decommission']}'" +
    " skipping..."
# Check 'rs_run_state' and skip if the instance is rebooting or entering the stop state
elsif ['shutting-down:reboot', 'shutting-down:stop'].include?(get_rs_run_state)
  log 'Skipping deletion of volumes as the instance is either rebooting or entering the stop state...'
# Detach and delete the volumes if the above safety conditions are satisfied
else
  # The connection hash to use to connect to MySQL
  mysql_connection_info = {
    :host => 'localhost',
    :username => 'root',
    :password => node['rs-mysql']['server_root_password']
  }

  # Drop the application database
  mysql_database 'drop application database' do
    connection mysql_connection_info
    database_name node['rs-mysql']['application_database_name']
    action :drop
    only_if { node['rs-mysql']['application_database_name'] }
  end

  # Delete the link created as /var/lib/mysql
  link '/var/lib/mysql' do
    action :delete
    only_if 'test -L /var/lib/mysql'
  end

  directory '/var/lib/mysql' do
    owner 'mysql'
    group 'mysql'
    recursive true
    action :create
  end

  mysql_data_dir = "#{node['rs-mysql']['device']['mount_point']}/mysql"

  # Move the data from the volume to the /var/lib/mysql directory
  bash 'move mysql data back from datadir' do
    code "mv #{mysql_data_dir}/* /var/lib/mysql"
    only_if '[ `stat -c %h /var/lib/mysql/` -eq 2 ]'
    only_if "test -d #{mysql_data_dir}"
  end

  # Remove innodb logfiles from /var/lib/mysql
  bash 'remove innodb log files' do
    code 'rm -f /var/lib/mysql/ib_logfile*'
    only_if 'test -f /var/lib/mysql/ib_logfile0'
  end

  # Override mysql cookbook attributes

  # Override the mysql/bind_address attribute with the server IP since
  # node['cloud']['local_ipv4'] returns an inconsistent type on AWS (String) and Google (Array) clouds
  bind_ip_address = RsMysql::Helper.get_bind_ip_address(node)
  Chef::Log.info "Overriding mysql/bind_address to '#{bind_ip_address}'..."
  node.override['mysql']['bind_address'] = bind_ip_address
  Chef::Log.info 'Overriding mysql/tunable/log_bin to false...'
  node.override['mysql']['tunable']['log_bin'] = false
  Chef::Log.info 'Overriding mysql server passwords...'
  node.override['mysql']['server_root_password'] = node['rs-mysql']['server_root_password']
  node.override['mysql']['server_debian_password'] = node['rs-mysql']['server_root_password']
  node.override['mysql']['server_repl_password'] = node['rs-mysql']['server_repl_password']

  include_recipe 'mysql::server'

  nickname = node['rs-mysql']['device']['nickname']

  # If LVM is used, we will have one or more devices with the device nickname appended with the device number. Destroy
  # the LVM conditionally and then detach and delete all the volumes.
  if is_lvm_used?(node['rs-mysql']['device']['mount_point'])
    # Remove any characters other than alphanumeric and dashes and replace with dashes
    sanitized_nickname = nickname.downcase.gsub(/[^-a-z0-9]/, '-')

    # Construct the logical volume from the name of the volume group and the name of the logical volume similar to how the
    # lvm cookbook constructs the name during the creation of the logical volume
    logical_volume_device = "/dev/mapper/#{to_dm_name("#{sanitized_nickname}-vg")}-#{to_dm_name("#{sanitized_nickname}-lv")}"

    log "Unmounting #{node['rs-mysql']['device']['mount_point']}"
    # There might still be some open files from the mount point if the database is bigger. Just ignore the failure for
    # now.
    mount node['rs-mysql']['device']['mount_point'] do
      device logical_volume_device
      ignore_failure true
      action [:umount, :disable]
    end

    log "LVM is used on the device(s). Cleaning up the LVM."
    # Clean up the LVM conditionally
    ruby_block 'clean up LVM' do
      block do
        remove_lvm("#{sanitized_nickname}-vg")
      end
    end

    # Detach and delete all attached volumes
    1.upto(node['rs-mysql']['device']['count'].to_i) do |device_num|
      rightscale_volume "#{nickname}_#{device_num}" do
        action [:detach, :delete]
      end
    end
  # If LVM is not used, we only have a single device. In this case, unmount, detach and delete the volume.
  else
    # Unmount the volume
    log "Unmounting #{node['rs-mysql']['device']['mount_point']}"
    # There might still be some open files from the mount point if the database is bigger. Just ignore the failure for
    # now.
    mount node['rs-mysql']['device']['mount_point'] do
      device lazy { node['rightscale_volume'][nickname]['device'] }
      ignore_failure true
      action [:umount, :disable]
      only_if { node.attribute?('rightscale_volume') && node['rightscale_volume'].attribute?(nickname) }
    end

    # Detach and delete the volume
    log 'LVM was not used on the device, simply detaching the deleting the device.'
    rightscale_volume nickname do
      action [:detach, :delete]
    end
  end
end
