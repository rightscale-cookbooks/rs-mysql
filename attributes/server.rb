#
# Cookbook Name:: rs-mysql
# Attribute:: server
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

# The server usage method. It should either be 'dedicated' or 'shared'. In a 'dedicated' server, all
# resources are dedicated to MySQL. In a 'shared' server, MySQL utilizes only half of the server resources.
#
default['rs-mysql']['server_usage'] = 'dedicated'

# The MySQL server's root password
default['rs-mysql']['server_root_password'] = nil

# The MySQL database application username
default['rs-mysql']['application_username'] = nil

# The MySQL database application password
default['rs-mysql']['application_password'] = nil

# The previleges given to the application user
default['rs-mysql']['application_user_privileges'] = [:select, :update, :insert]

# The name of MySQL database
default['rs-mysql']['database_name'] = nil
