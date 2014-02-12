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

# Calculate MySQL tunable attributes based on system memory and server usage type of 'dedicated' or 'shared'.
# Attributes will be placed in node['mysql']['tunable'] namespace.
RsMysql::Tuning.tune_attributes(
  node.override['mysql']['tunable'],
  node['memory']['total'],
  node['rs-mysql']['server_usage']
)

# Override mysql cookbook attributes
node.override['mysql']['server_root_password'] = node['rs-mysql']['server_root_password']
node.override['mysql']['server_debian_password'] = node['rs-mysql']['server_root_password']
node.override['mysql']['server_repl_password'] = node['rs-mysql']['server_repl_password']

Chef::Log.info "Overriding mysql/tunable/expire_log_days to '2'"
node.override['mysql']['tunable']['expire_log_days'] = 2

# The directory that contains the MySQL binary logs.
Chef::Log.info "Overriding mysql/server/directories/bin_log_dir to '#{node['mysql']['data_dir']}/mysql_binlogs'"
node.override['mysql']['server']['directories']['bin_log_dir'] = "#{node['mysql']['data_dir']}/mysql_binlogs"

Chef::Log.info "Overriding mysql/tunable/log_bin to '#{node['mysql']['data_dir']}/mysql_binlogs/mysql-bin'"
node.override['mysql']['tunable']['log_bin'] = "#{node['mysql']['data_dir']}/mysql_binlogs/mysql-bin"

Chef::Log.info "Overriding mysql/tunable/binlog_format to 'MIXED'"
node.override['mysql']['tunable']['binlog_format'] = 'MIXED'

# Convert the server IP to an integer and use it for the server-id attribute in my.cnf
server_id = RsMysql::Helper.get_server_ip(node).to_i
Chef::Log.info "Overriding mysql/tunable/server_id to '#{server_id}'"
node.override['mysql']['tunable']['server_id'] = server_id

include_recipe 'mysql::server'
include_recipe 'database::mysql'
include_recipe 'rightscale_tag::default'

# Setup database tags on the server
rightscale_tag_database node['rs-mysql']['lineage'] do
  bind_ip_address node['mysql']['bind_address']
  bind_port node['mysql']['port']
  action :create
end

# Setup MySQL collectd plugin
if node['rightscale'] && node['rightscale']['instance_uuid']
  Chef::Log.info "Overriding collectd/fqdn to '#{node['rightscale']['instance_uuid']}'..."
  node.override['collectd']['fqdn'] = node['rightscale']['instance_uuid']
end

log "Installing MySQL collectd plugin..."

# On CentOS the MySQL collectd plugin is installed separately
package "collectd-mysql" do
  only_if { node['platform'] =~ /redhat|centos/ }
end

include_recipe 'collectd::default'

collectd_plugin "mysql" do
  options({
    "Host" => "localhost",
    "User" => "root",
    "Password" => node['mysql']['server_root_password']
  })
end

# The connection hash to use to connect to MySQL
mysql_connection_info = {
  :host => 'localhost',
  :username => 'root',
  :password => node['rs-mysql']['server_root_password']
}

# Create the application database
if node['rs-mysql']['application_database_name']
  mysql_database node['rs-mysql']['application_database_name'] do
    connection mysql_connection_info
    action :create
  end
end

if node['rs-mysql']['application_username'] && node['rs-mysql']['application_password']
  raise 'rs-mysql/application_database_name is required for creating user!' unless node['rs-mysql']['application_database_name']

  # Create the application user
  mysql_database_user node['rs-mysql']['application_username'] do
    connection mysql_connection_info
    password node['rs-mysql']['application_password']
    database_name node['rs-mysql']['application_database_name']
    host 'localhost'
    privileges node['rs-mysql']['application_user_privileges']
    action [:create, :grant]
  end
end
