#
# Cookbook Name:: rs-mysql
# Recipe:: server
#
# Copyright (C) 2013 RightScale, Inc.
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

# The directory that contains the MySQL binary logs.
# The attribute mysql/server/directories contains directories that belong to MySQL. These directories will be creted by
# the mysql::server recipe with correct ownership.
node.override['mysql']['server']['directories']['bin_log_dir'] = "#{node['mysql']['data_dir']}/mysql_binlogs"

# TODO: Override master server specific attributes
node.override['mysql']['tunable']['log_bin'] = "#{node['mysql']['data_dir']}/mysql_binlogs/mysql-bin"
node.override['mysql']['tunable']['binlog_format'] = 'MIXED'
node.override['mysql']['tunable']['read_only'] = false
node.override['mysql']['tunable']['server_id'] = RsMysql::Helper.get_server_ip(node).to_i

include_recipe 'rs-mysql::server'

# The connection hash to use to connect to mysql
mysql_connection_info = {
  :host => 'localhost',
  :username => 'root',
  :password => node['rs-mysql']['server_root_password']
}

# Reset the master so the bin logs don't have information about the system tables that get created during the MySQL
# installation.
mysql_database 'reset master' do
  database_name 'mysql'
  connection mysql_connection_info
  sql 'RESET MASTER'
  action :query
end

# TODO: Include 'rs-machine_tag::database' recipe
