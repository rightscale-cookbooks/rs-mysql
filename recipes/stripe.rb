#
# Cookbook Name:: rs-mysql
# Recipe:: stripe
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

device_count = node['rs-mysql']['device']['count'].to_i
device_nickname = node['rs-mysql']['device']['nickname']
size = node['rs-mysql']['device']['volume_size'].to_i

raise 'rs-mysql/device/count should be at least 2 for setting up stripe' if device_count < 2

detach_timeout = node['rs-mysql']['device']['detach_timeout'].to_i * device_count

execute "set decommission timeout to #{detach_timeout}" do
  command "rs_config --set decommission_timeout #{detach_timeout}"
  not_if "[ `rs_config --get decommission_timeout` -eq #{detach_timeout} ]"
end

each_device_size = (size.to_f / device_count.to_f).ceil

Chef::Log.info "Total size is: #{size}"
Chef::Log.info "Device count in logical volume is set to: #{device_count}"
Chef::Log.info "Each device in the logical volume will be created of size: #{each_device_size}"

device_nicknames = []

# Cloud-specific volume options
volume_options = {}
volume_options[:iops] = node['rs-mysql']['device']['iops'] if node['rs-mysql']['device']['iops']
volume_options[:volume_type] = node['rs-mysql']['device']['volume_type'] if node['rs-mysql']['device']['volume_type']
volume_options[:controller_type] = node['rs-mysql']['device']['controller_type'] if node['rs-mysql']['device']['controller_type']

# Install packages required for setting up LVM
include_recipe 'lvm::default'

new_mysql_dir = "#{node['rs-mysql']['device']['mount_point']}/mysql"

# rs-mysql/restore/lineage is empty, creating new volume(s) and setting up LVM
if node['rs-mysql']['restore']['lineage'].to_s.empty?
  1.upto(device_count) do |device_num|
    device_nicknames << "#{device_nickname}_#{device_num}"
    rightscale_volume "#{device_nickname}_#{device_num}" do
      size each_device_size
      options volume_options
      action [:create, :attach]
    end
  end
# rs-mysql/restore/lineage is set, restore from the backup
else
  rightscale_backup device_nickname do
    lineage node['rs-mysql']['restore']['lineage']
    timestamp node['rs-mysql']['restore']['timestamp'].to_i if node['rs-mysql']['restore']['timestamp']
    size each_device_size
    options volume_options
    action :restore
  end

  directory '/var/lib/mysql' do
    recursive true
    action :delete
  end

  link '/var/lib/mysql' do
    to new_mysql_dir
  end
end

# Remove any characters other than alphanumeric and dashes and replace with dashes
sanitized_nickname = device_nickname.downcase.gsub(/[^-a-z0-9]/, '-')

# Setup LVM on the volumes. The following resources will:
#   - initialize the physical volumes for use by LVM
#   - create volume group and logical volume
#   - format and mount the logical volume
lvm_volume_group "#{sanitized_nickname}-vg" do
  physical_volumes(lazy do
    if node['rs-mysql']['restore']['lineage'].to_s.empty?
      device_nicknames.map { |device_nickname| node['rightscale_volume'][device_nickname]['device'] }
    else
      node['rightscale_backup'][device_nickname]['devices']
    end
  end)
end

lvm_logical_volume "#{sanitized_nickname}-lv" do
  group "#{sanitized_nickname}-vg"
  size '100%VG'
  filesystem node['rs-mysql']['device']['filesystem']
  mount_point node['rs-mysql']['device']['mount_point']
  stripes device_count
  stripe_size node['rs-mysql']['device']['stripe_size']
end

# Make sure that there is a 'mysql' directory on the mount point of the volume
directory new_mysql_dir do
  owner 'mysql'
  group 'mysql'
  mode '0755'
  action :create
end

# Make sure that the permissions for the 'mysql' directory are set correctly.
# When recovering from a backup uids could have changed.
execute "change permissions #{new_mysql_dir} owner" do
  command "chown --recursive --silent mysql:mysql #{new_mysql_dir}"
  not_if "stat -c %U #{new_mysql_dir}/mysql |grep mysql"
end

# Override the mysql data_dir. This will do the following:
#   - Change the data_dir setting in the my.cnf to the new location.
#   - Move the data from the /var/lib/mysql to this new location. This will be done only if the new location is
#     empty.
node.override['mysql']['data_dir'] = new_mysql_dir
node.override['mysql']['server']['directories']['log_dir'] = new_mysql_dir

# Include the rs-mysql::default so the tuning attributes and tags are set properly.
include_recipe 'rs-mysql::default'
