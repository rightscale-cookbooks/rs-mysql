#
# Cookbook Name:: rs-mysql
# Recipe:: dump_import
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

# Install git client
include_recipe 'git'

# Set temporary file locations.
key_file = '/tmp/git_key'
ssh_wrapper = '/tmp/git_ssh.sh'
destination_dir = '/tmp/git_download'

# Create private key file
ssh_private_key = node['rs-mysql']['import']['private_key']
if ssh_private_key
  file key_file do
    owner 'root'
    group 'root'
    mode '0700'
    content ssh_private_key
    action :create
  end

  # Create bash script to use for GIT_SSH
  bash_script = %Q{exec ssh -o StrictHostKeyChecking=no -i #{key_file} "$@"}

  # Create wrapper script used if private key was provided
  file ssh_wrapper do
    owner 'root'
    group 'root'
    mode '0700'
    content bash_script
    action :create
  end
end

# Download repository
git destination_dir do
  repository node['rs-mysql']['import']['repository']
  revision node['rs-mysql']['import']['revision']
  ssh_wrapper ssh_wrapper if ssh_private_key
end

# Immediatly delete sensitive temporary files
[key_file, ssh_wrapper].each do |filename|
  file filename do
    action :delete
  end
end

dump_file = ::File.join(destination_dir, node['rs-mysql']['import']['dump_file'])
resource_name = ::File.basename(dump_file) + '-' + node['rs-mysql']['import']['revision']
touch_file = "/var/lib/rightscale/rs-mysql-import-#{resource_name}.touch"

# Check if touch_file exists, signifying that an import with this dump file already occurred.
if ::File.exists?(touch_file)
  log "The dump file was already imported at #{::File.ctime(touch_file)}. Therefore, no data will be imported."
elsif node['rs-mysql']['application_database_name'].to_s.empty?
  log "rs-mysql/application_database_name is required but not set.  Therefore, no data will be imported."
else
  # Make sure directory /var/lib/rightscale exists which will contain the touch file
  directory '/var/lib/rightscale' do
    mode 0755
    recursive true
    action :create
  end

  # Prepare for creating the touch file after dump has been imported. Once the touch file has
  # been created importing will be skipped if the recipe runs again with the same dump_file name
  # and revision.
  file touch_file do
    action :nothing
  end

  # Determine by filename extension the command to read in the dump file
  read_command =
    case dump_file
    when /\.gz$/
      "gunzip --stdout '#{dump_file}'"
    when /\.bz2$/
      "bunzip2 --stdout '#{dump_file}'"
    when /\.xz$/
      "xz --decompress --stdout '#{dump_file}'"
    else
      "cat '#{dump_file}'"
    end

  # The connection hash to use to connect to MySQL
  mysql_connection_info = {
    :host => 'localhost',
    :username => 'root',
    :password => node['rs-mysql']['server_root_password']
  }

  # Import from MySQL dump.
  # Note: the application database must exist beforehand due to a condition
  # in the 'database' cookbook.  Otherwise importing will not occur.
  mysql_database resource_name do
    connection mysql_connection_info
    database_name node['rs-mysql']['application_database_name']
    sql do
      streaming_file = Mixlib::ShellOut.new(read_command).run_command
      streaming_file.error!
      streaming_file.stdout
    end
    action :query
    notifies :touch, "file[#{touch_file}]", :immediately
  end

end

# After importing dump file, delete entire downloaded destination directory.
directory destination_dir do
  recursive true
  action :delete
end
