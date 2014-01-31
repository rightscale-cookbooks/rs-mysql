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

directory "#{node['mysql']['data_dir']}/mysql_binlogs" do
  owner 'mysql'
  group 'mysql'
  recursive true
end

# TODO: Override master server specific attributes
node.override['mysql']['tunable']['log_bin'] = "#{node['mysql']['data_dir']}/mysql_binlogs/mysql-bin"
node.override['mysql']['tunable']['binlog_format'] = 'MIXED'
node.override['mysql']['tunable']['read_only'] = false
node.override['mysql']['tunable']['server_id'] = node['rightscale']['server_uuid']

include_recipe 'rs-mysql::server'

# The mysql service should be restarted if the server-id is changed. The mysql cookbook reloads the service
# if the my.cnf is changed but that is not sufficient.
#
#service 'mysql' do
#  action :restart
#end

# TODO: Include 'rs-machine_tag::database' recipe
