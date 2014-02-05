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

RsMysql::Tuning.tune_attributes(
  node.override['mysql']['tunable'],
  node['memory']['total'],
  node['rs-mysql']['server_usage']
)

node.override['mysql']['server_root_password'] = node['rs-mysql']['server_root_password']
node.override['mysql']['server_debian_password'] = node['rs-mysql']['server_root_password']
node.override['mysql']['server_repl_password'] = node['rs-mysql']['server_repl_password']
node.override['mysql']['tunable']['expire_log_days'] = 2

include_recipe 'mysql::server'


# Setup collectd mysql plugin

if node['rightscale'] && node['rightscale']['instance_uuid']
  node.override['collectd']['fqdn'] = node['rightscale']['instance_uuid']
end

log "Installing MySQL collectd plugin"

package "collectd-mysql" do
  only_if { node['platform'] =~ /redhat|centos/ }
end

include_recipe 'collectd::default'

include_recipe 'database::mysql'

collectd_plugin "mysql" do
  options({
    "Host" => "localhost",
    "User" => "root",
    "Password" => node['mysql']['server_root_password']
  })
end

# The connection hash to use to connect to mysql
mysql_connection_info = {
  :host => 'localhost',
  :username => 'root',
  :password => node['rs-mysql']['server_root_password']
}

# Create the database
mysql_database node['rs-mysql']['application_database_name'] do
  only_if { node['rs-mysql']['application_database_name'] }
  connection mysql_connection_info
  action :create
end

if node['rs-mysql']['application_username'] && node['rs-mysql']['application_password']
  raise 'The rs-mysql/application_database_name is required for creating user' unless node['rs-mysql']['application_database_name']

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
