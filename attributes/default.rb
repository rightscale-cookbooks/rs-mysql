#
# Cookbook Name:: rs-mysql
# Attribute:: server
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

# The server usage method. It should either be 'dedicated' or 'shared'. In a 'dedicated' server, all
# resources are dedicated to MySQL. In a 'shared' server, MySQL utilizes only half of the server resources.
#
default['rs-mysql']['server_usage'] = 'dedicated'

# The MySQL server's root password
default['rs-mysql']['server_root_password'] = nil

# The MySQL server's replication password
default['rs-mysql']['server_repl_password'] = nil

# The MySQL database application username
default['rs-mysql']['application_username'] = nil

# The MySQL database application password
default['rs-mysql']['application_password'] = nil

# The privileges given to the application user
default['rs-mysql']['application_user_privileges'] = [:select, :update, :insert]

# The name of MySQL database
default['rs-mysql']['application_database_name'] = nil

# MySQL bind network interface - 'private' or 'public'
default['rs-mysql']['bind_network_interface'] = 'private'

# MySQL bind IP address
default['rs-mysql']['bind_address'] = nil

# The fully-qualified domain name of the master database server
default['rs-mysql']['dns']['master_fqdn'] = nil

# The DNS user key to create/update DNS records
default['rs-mysql']['dns']['user_key'] = nil

# The DNS secret key to create/update DNS records
default['rs-mysql']['dns']['secret_key'] = nil

# Authentication key used for fetching from private repositories.
default['rs-mysql']['import']['private_key'] = nil

# Git repository where dump file to import is located.
default['rs-mysql']['import']['repository'] = nil

# Git revision or branch to import.
default['rs-mysql']['import']['revision'] = nil

# Dump file location in repository to import.
default['rs-mysql']['import']['dump_file'] = nil

# Sets up empty collectd options for v5
default['rs-mysql']['collectd']['mysql']['Host'] = 'localhost'
default['rs-mysql']['collectd']['mysql']['User'] = 'root'
default['rs-mysql']['collectd']['mysql']['Socket'] = '/var/run/mysql-default/mysqld.sock'
default['rs-mysql']['collectd']['mysql']['Password'] = node['rs-mysql']['server_root_password']
default['rs-mysql']['startup-timeout'] = 300
default['rs-mysql']['mysql']['version'] = '5.5'

class Chef::Recipe
  include MysqlCookbook::HelpersBase
end
# mysql attributes
default['mysql']['tunable']['log_error'] = '/var/log/mysql-default/error.log'
default['mysql']['port'] = 3306
default['mysql']['data_dir'] = '/var/lib/mysql-default'
