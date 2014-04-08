#
# Cookbook Name:: rs-mysql
# Recipe:: master
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

marker 'recipe_start_rightscale' do
  template 'rightscale_audit_entry.erb'
end

# Override master specific attributes
Chef::Log.info "Overriding mysql/tunable/read_only to 'false'..."
node.override['mysql']['tunable']['read_only'] = false

include_recipe 'rs-mysql::default'

rightscale_tag_database node['rs-mysql']['lineage'] do
  role 'slave'
  bind_ip_address node['mysql']['bind_address']
  bind_port node['mysql']['port']
  action :delete
end

# Set up the tags for the master server.
# See https://github.com/rightscale-cookbooks/rightscale_tag#database-servers for more information about the
# `rightscale_tag_database` resource.
rightscale_tag_database node['rs-mysql']['lineage'] do
  role 'master'
  bind_ip_address node['mysql']['bind_address']
  bind_port node['mysql']['port']
  action :create
end

# The connection hash to use to connect to mysql
mysql_connection_info = {
  :host => 'localhost',
  :username => 'root',
  :password => node['rs-mysql']['server_root_password'],
}

mysql_database 'stop slave IO thread' do
  database_name 'mysql'
  connection mysql_connection_info
  sql 'STOP SLAVE IO_THREAD'
  action :query
end

ruby_block 'wait for relay log read' do
  block do
    RsMysql::Helper.wait_for_relay_log_read(mysql_connection_info)
  end
end

mysql_database 'stop slave' do
  database_name 'mysql'
  connection mysql_connection_info
  sql 'STOP SLAVE'
  action :query
end

mysql_database 'reset slave' do
  database_name 'mysql'
  connection mysql_connection_info
  sql 'RESET SLAVE'
  action :query
  notifies :restart, "service[#{node['mysql']['server']['service_name'] || 'mysql'}]"
end

# Reset the master so the bin logs don't have information about the system tables that get created during the MySQL
# installation.
mysql_database 'reset master' do
  database_name 'mysql'
  connection mysql_connection_info
  sql 'RESET MASTER'
  action :query
end
