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

# Override slave specific attributes
Chef::Log.info "Overriding mysql/tunable/read_only to 'true'..."
node.override['mysql']['tunable']['read_only'] = true

include_recipe 'rs-mysql::server'

# Set up tags for slave database
rightscale_tag_database node['rs-mysql']['lineage'] do
  role 'slave'
  bind_ip_address node['mysql']['bind_address']
  bind_port node['mysql']['port']
  action :create
end

class Chef::Recipe
  include Rightscale::RightscaleTag
end

# Find the most recent master database in the deployment
latest_master = nil
Chef::Log.info "Finding master database servers with lineage '#{node['rs-mysql']['lineage']}' in the deployment..."
master_dbs = find_database_servers(node, node['rs-mysql']['lineage'], 'master', {:only_latest_for_role => true})
if master_dbs.empty?
  raise "No master database for the lineage '#{node['rs-mysql']['lineage']}' found in the deployment!"
else
  latest_master = master_dbs.map { |uuid, server_hash| server_hash }.first
end

# The connection hash to use to connect to mysql
mysql_connection_info = {
  :host => 'localhost',
  :username => 'root',
  :password => node['rs-mysql']['server_root_password']
}

# Stop the slave
# TODO: v13 runs this twice. Do we still need to do this? If we need to, we can use `retries` and `retry_delay`.
#
mysql_database 'stop slave' do
  database_name 'mysql'
  connection mysql_connection_info
  sql 'STOP SLAVE'
  action :query
end

mysql_database 'change master host' do
  database_name 'mysql'
  connection mysql_connection_info
  sql "CHANGE MASTER TO" +
    " MASTER_HOST='#{latest_master['bind_ip_address']}'," +
    " MASTER_USER='repl'," +
    " MASTER_PASSWORD='#{node['rs-mysql']['server_repl_password']}'"
  action :query
end

mysql_database 'start slave' do
  database_name 'mysql'
  connection mysql_connection_info
  sql 'START SLAVE'
  action :query
end

# TODO: In v13 we run this 10 times and check for the 'Slave_IO_Running' and 'Slave_SQL_Running' to become 'yes'.
# Do we need a similar logic? Or there are better ways to determine if the slave is functional and its threads are
# running?
#
mysql_database 'show slave status' do
  database_name 'mysql'
  connection mysql_connection_info
  sql 'SHOW SLAVE STATUS'
  action :query
end
