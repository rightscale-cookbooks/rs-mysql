#
# Cookbook Name:: rs-mysql
# Recipe:: slave
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

class Chef::Recipe
  include Rightscale::RightscaleTag
end

# Override slave specific attributes
Chef::Log.info "Overriding mysql/tunable/read_only to 'true'..."
node.override['mysql']['tunable']['read_only'] = true

# Override the mysql/bind_address attribute with the private IP of the server since
# node['cloud']['local_ipv4'] returns an inconsistent type on AWS (String) and Google (Array) clouds
bind_ip_address = RsMysql::Helper.get_bind_ip_address(node)
Chef::Log.info "Overriding mysql/bind_address to '#{bind_ip_address}'..."
node.override['mysql']['bind_address'] = bind_ip_address

include_recipe 'rs-mysql::default'

# Find the most recent master database in the deployment
latest_master = nil
Chef::Log.info "Finding master database servers with lineage '#{node['rs-mysql']['lineage']}' in the deployment..."
master_dbs = find_database_servers(node, node['rs-mysql']['lineage'], 'master', {:only_latest_for_role => true})
if master_dbs.empty?
  raise "No master database for the lineage '#{node['rs-mysql']['lineage']}' found in the deployment!"
else
  latest_master = master_dbs.map { |uuid, server_hash| server_hash }.first
end

rightscale_tag_database node['rs-mysql']['lineage'] do
  role 'master'
  bind_ip_address node['mysql']['bind_address']
  bind_port node['mysql']['port']
  action :delete
end

# Set up tags for slave database.
# See https://github.com/rightscale-cookbooks/rightscale_tag#database-servers for more information about the
# `rightscale_tag_database` resource.
rightscale_tag_database node['rs-mysql']['lineage'] do
  role 'slave'
  bind_ip_address node['mysql']['bind_address']
  bind_port node['mysql']['port']
  action :create
end

# The connection hash to use to connect to mysql
mysql_connection_info = {
  :host => 'localhost',
  :username => 'root',
  :password => node['rs-mysql']['server_root_password']
}

mysql_database 'set global read only' do
  database_name 'mysql'
  connection mysql_connection_info
  sql 'SET GLOBAL READ_ONLY=1'
  action :query
end

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

# Verify if the slave is functional. See libraries/helper.rb for the definition of the verify_slave_fuctional method.
ruby_block 'verify slave running' do
  block do
    RsMysql::Helper.verify_slave_functional(mysql_connection_info, node['rs-mysql']['slave_functional_timeout'])
  end
end
