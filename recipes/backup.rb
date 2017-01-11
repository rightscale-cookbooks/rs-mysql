#
# Cookbook Name:: rs-mysql
# Recipe:: backup
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

# The version of the mysql cookbook we are using does not consistently set mysql/server/service_name
mysql_service_name = node['rs-mysql']['service_name']

marker 'recipe_start_rightscale' do
  template 'rightscale_audit_entry.erb'
end

include_recipe 'chef_handler::default'

# Create the backup error handler
cookbook_file "#{node['chef_handler']['handler_path']}/rs-mysql_backup.rb" do
  source 'backup_error_handler.rb'
  action :create
end

# Enable the backup error handler so the filesystem is unfrozen in case of a backup failure
chef_handler 'Rightscale::BackupErrorHandler' do
  source "#{node['chef_handler']['handler_path']}/rs-mysql_backup.rb"
  action :enable
end

# The connection hash to use to connect to mysql
mysql_connection_info = {
  host: 'localhost',
  username: 'root',
  password: node['rs-mysql']['server_root_password'],
  default_file: "/etc/#{mysql_service_name}/my.cnf"
}

mysql_database 'flush tables with read lock' do
  database_name 'mysql'
  connection mysql_connection_info
  sql 'FLUSH TABLES WITH READ LOCK'
  action :query
end

file 'generate master info JSON file' do
  content lazy { JSON.pretty_generate(get_master_info(mysql_connection_info)) }
  path "#{node['rs-mysql']['device']['mount_point']}/mysql_master_info.json"
  action :create
end

device_nickname = node['rs-mysql']['device']['nickname']

log "Freezing the filesystem mounted on #{node['rs-mysql']['device']['mount_point']}"

filesystem "freeze #{device_nickname}" do
  label device_nickname
  mount node['rs-mysql']['device']['mount_point']
  action :freeze
end

log "Taking a backup of lineage '#{node['rs-mysql']['backup']['lineage']}'"

rightscale_backup device_nickname do
  lineage node['rs-mysql']['backup']['lineage']
  action :create
end

log "Unfreezing the filesystem mounted on #{node['rs-mysql']['device']['mount_point']}"

filesystem "unfreeze #{device_nickname}" do
  label device_nickname
  mount node['rs-mysql']['device']['mount_point']
  action :unfreeze
end

file 'delete master info JSON file' do
  path "#{node['rs-mysql']['device']['mount_point']}/mysql_master_info.json"
  action :delete
end

mysql_database 'unlock tables' do
  database_name 'mysql'
  connection mysql_connection_info
  sql 'UNLOCK TABLES'
  action :query
end

log 'Cleaning up old snapshots'

rightscale_backup device_nickname do
  lineage node['rs-mysql']['backup']['lineage']
  keep_last node['rs-mysql']['backup']['keep']['keep_last'].to_i
  dailies node['rs-mysql']['backup']['keep']['dailies'].to_i
  weeklies node['rs-mysql']['backup']['keep']['weeklies'].to_i
  monthlies node['rs-mysql']['backup']['keep']['monthlies'].to_i
  yearlies node['rs-mysql']['backup']['keep']['yearlies'].to_i
  action :cleanup
end
