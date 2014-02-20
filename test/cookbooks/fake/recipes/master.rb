#
# Cookbook Name:: fake
# Recipe:: master
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

# Tags for the fake master database server
tags = [
  "server:uuid=1111111111",
  "database:active=true",
  "database:master_active=#{Time.now.to_i}",
  "database:lineage=#{node['rs-mysql']['lineage']}",
  "database:bind_ip_address=173.227.0.5",
  "database:bind_port=3306"
]

# The file containing the master server tags must be created in
# in this path so that machine tag search work as intended in a
# vagrant environment
tags_path = '/vagrant/cache_dir/machine_tag_cache/master-host'
::FileUtils.mkdir_p(tags_path)
::File.open(::File.join(tags_path, 'tags.json'), 'w') { |file| file.write(::JSON.pretty_generate(tags)) }
