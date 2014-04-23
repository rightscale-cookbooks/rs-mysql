#
# Cookbook Name:: rs-mysql
# Recipe:: default
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

# Override the mysql/bind_address attribute with the server IP since
# node['cloud']['local_ipv4'] returns an inconsistent type on AWS (String) and Google (Array) clouds
bind_ip_address = RsMysql::Helper.get_bind_ip_address(node)
Chef::Log.info "Overriding mysql/bind_address to '#{bind_ip_address}'..."
node.override['mysql']['bind_address'] = bind_ip_address

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

Chef::Log.info 'Overriding mysql/tunable/expire_log_days to 2'
node.override['mysql']['tunable']['expire_log_days'] = 2

# The directory that contains the MySQL binary logs. This directory will only be created as part of the initial MySQL
# installation and setup. If the data directory is changed, this should not be creaed again as the data from
# /var/lib/mysql will be moved to the new location.
if node['mysql']['data_dir'] == '/var/lib/mysql'
  Chef::Log.info "Overriding mysql/server/directories/bin_log_dir to '#{node['mysql']['data_dir']}/mysql_binlogs'"
  node.override['mysql']['server']['directories']['bin_log_dir'] = "#{node['mysql']['data_dir']}/mysql_binlogs"
end

Chef::Log.info "Overriding mysql/tunable/log_bin to '#{node['mysql']['data_dir']}/mysql_binlogs/mysql-bin'"
node.override['mysql']['tunable']['log_bin'] = "#{node['mysql']['data_dir']}/mysql_binlogs/mysql-bin"

Chef::Log.info "Overriding mysql/tunable/binlog_format to 'MIXED'"
node.override['mysql']['tunable']['binlog_format'] = 'MIXED'

# Convert the server IP to an integer and use it for the server-id attribute in my.cnf
server_id = RsMysql::Helper.get_server_ip(node).to_i
Chef::Log.info "Overriding mysql/tunable/server_id to '#{server_id}'"
node.override['mysql']['tunable']['server_id'] = server_id

mysql_service_name = node['mysql']['server']['service_name'] || 'mysql'

service mysql_service_name do
  action :stop
  only_if do
    ::File.exists?("#{node['mysql']['data_dir']}/ib_logfile0") &&
    ::File.size("#{node['mysql']['data_dir']}/ib_logfile0") != RsMysql::Tuning.megabytes_to_bytes(
      node['mysql']['tunable']['innodb_log_file_size']
    )
  end
end

execute 'delete innodb log files' do
  command "rm -f #{node['mysql']['data_dir']}/ib_logfile*"
  only_if do
    ::File.exists?("#{node['mysql']['data_dir']}/ib_logfile0") &&
    ::File.size("#{node['mysql']['data_dir']}/ib_logfile0") != RsMysql::Tuning.megabytes_to_bytes(
      node['mysql']['tunable']['innodb_log_file_size']
    )
  end
end

data_dir = node['mysql']['data_dir']

execute 'update mysql binlog index with new data_dir' do
  command "sed -i -r -e 's#^.*/(mysql_binlogs/.*)$##{data_dir}/\\1#' '#{data_dir}/mysql_binlogs/mysql-bin.index'"
  only_if { ::File.exists?("#{data_dir}/mysql_binlogs/mysql-bin.index") }
end

include_recipe 'mysql::server'
include_recipe 'database::mysql'
include_recipe 'rightscale_tag::default'
include_recipe 'rightscale_volume::default'
include_recipe 'rightscale_backup::default'

# Setup database tags on the server.
# See https://github.com/rightscale-cookbooks/rightscale_tag#database-servers for more information about the
# `rightscale_tag_database` resource.
rightscale_tag_database node['rs-mysql']['backup']['lineage'] do
  bind_ip_address node['mysql']['bind_address']
  bind_port node['mysql']['port']
  action :create
end

# The connection hash to use to connect to MySQL
mysql_connection_info = {
  :host => 'localhost',
  :username => 'root',
  :password => node['rs-mysql']['server_root_password']
}

# Create the application database
mysql_database 'application database' do
  connection mysql_connection_info
  database_name node['rs-mysql']['application_database_name']
  action :create
  not_if { node['rs-mysql']['application_database_name'].to_s.empty? }
end

if !node['rs-mysql']['application_username'].to_s.empty? && !node['rs-mysql']['application_password'].to_s.empty?
  if node['rs-mysql']['application_database_name'].to_s.empty?
    raise 'rs-mysql/application_database_name is required for creating user!'
  end

  # Create the application user to connect from localhost and any other hosts
  ['localhost', '%'].each do |hostname|
    mysql_database_user node['rs-mysql']['application_username'] do
      connection mysql_connection_info
      password node['rs-mysql']['application_password']
      database_name node['rs-mysql']['application_database_name']
      host hostname
      privileges node['rs-mysql']['application_user_privileges']
      action [:create, :grant]
    end
  end

  # Create the application user to connect from any host
  mysql_database_user node['rs-mysql']['application_username'] do
    connection mysql_connection_info
    password node['rs-mysql']['application_password']
    database_name node['rs-mysql']['application_database_name']
    host '%'
    privileges node['rs-mysql']['application_user_privileges']
    action [:create, :grant]
  end
end
