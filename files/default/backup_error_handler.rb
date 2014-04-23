#
# Cookbook Name:: rs-mysql
# Handler:: backup_error_handler
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

module Rightscale
  class BackupErrorHandler < Chef::Handler
    def report
      nickname = run_context.node['rs-mysql']['device']['nickname']
      filesystem_resource = run_context.resource_collection.lookup("filesystem[unfreeze #{nickname}]")
      filesystem_resource.run_action(:unfreeze)
      mysql_database_resource = run_context.resource_collection.lookup('mysql_database[unlock tables]')
      mysql_database_resource.run_action(:query)
    end
  end
end
