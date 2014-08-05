#
# Cookbook Name:: rs-mysql
# Recipe:: volume
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

detach_timeout = node['rs-mysql']['device']['detach_timeout'].to_i
device_nickname = node['rs-mysql']['device']['nickname']
size = node['rs-mysql']['device']['volume_size'].to_i

execute "set decommission timeout to #{detach_timeout}" do
  command "rs_config --set decommission_timeout #{detach_timeout}"
  not_if "[ `rs_config --get decommission_timeout` -eq #{detach_timeout} ]"
end


# Cloud-specific volume options
volume_options = {}
volume_options[:iops] = node['rs-mysql']['device']['iops'] if node['rs-mysql']['device']['iops']
volume_options[:volume_type] = node['rs-mysql']['device']['volume_type'] if node['rs-mysql']['device']['volume_type']
volume_options[:controller_type] = node['rs-mysql']['device']['controller_type'] if node['rs-mysql']['device']['controller_type']


new_mysql_dir = "#{node['rs-mysql']['device']['mount_point']}/mysql"

# rs-mysql/restore/lineage is empty, creating new volume
if node['rs-mysql']['restore']['lineage'].to_s.empty?
  log "Creating a new volume '#{device_nickname}' with size #{size}"
  rightscale_volume device_nickname do
    size size
    options volume_options
    action [:create, :attach]
  end

  filesystem device_nickname do
    fstype node['rs-mysql']['device']['filesystem']
    device lazy { node['rightscale_volume'][device_nickname]['device'] }
    mkfs_options node['rs-mysql']['device']['mkfs_options']
    mount node['rs-mysql']['device']['mount_point']
    action [:create, :enable, :mount]
  end
# rs-mysql/restore/lineage is set, restore from the backup
else
  node.override['rs-mysql']['lineage'] = node['rs-mysql']['restore']['lineage']
  lineage = node['rs-mysql']['restore']['lineage']
  timestamp = node['rs-mysql']['restore']['timestamp']

  message = "Restoring volume '#{device_nickname}' from backup using lineage '#{lineage}'"
  message << " and using timestamp '#{timestamp}'" if timestamp

  log message

  rightscale_backup device_nickname do
    lineage node['rs-mysql']['restore']['lineage']
    timestamp node['rs-mysql']['restore']['timestamp'].to_i if node['rs-mysql']['restore']['timestamp']
    size size
    options volume_options
    action :restore
  end

  directory node['rs-mysql']['device']['mount_point'] do
    recursive true
  end

  mount node['rs-mysql']['device']['mount_point'] do
    fstype node['rs-mysql']['device']['filesystem']
    device lazy { node['rightscale_backup'][device_nickname]['devices'].first }
    action [:mount, :enable]
  end

  directory '/var/lib/mysql' do
    recursive true
    action :delete
  end

  link '/var/lib/mysql' do
    to new_mysql_dir
  end
end

# Make sure that there is a 'mysql' directory on the mount point of the volume
directory new_mysql_dir do
  owner 'mysql'
  group 'mysql'
  action :create
end

# Override the mysql data_dir. This will do the following:
#   - Change the data_dir setting in the my.cnf to the new location.
#   - Move the data from the /var/lib/mysql to this new location. This will be done only if the new location is
#     empty.
node.override['mysql']['data_dir'] = new_mysql_dir
node.override['mysql']['server']['directories']['log_dir'] = new_mysql_dir

# Include the rs-mysql::default so the tuning attributes and tags are set properly.
include_recipe 'rs-mysql::default'
