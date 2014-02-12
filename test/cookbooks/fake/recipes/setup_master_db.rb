#
# Cookbook Name:: fake
# Recipe:: setup_master_db
#
# Copyright (C) 2013 RightScale, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

tag_folder_name = "/vagrant/cache_dir/machine_tag_cache/test"

FileUtils.mkdir_p(tag_folder_name)

tags = [
  "database:active=true",
  "database:lineage=#{node['rs-mysql']['lineage']}",
  "database:bind_ip_address=#{node['mysql']['bind_address']}",
  "database:bind_port=#{node['mysql']['port']}"
]

File.open("#{tag_folder_name}/tags.json", 'w') do |f|
  tags.each { |element| f.puts(element)}
end
