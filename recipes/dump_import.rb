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

#ssh_private_key = node['rs-mysql']['import']['private_key']
ssh_private_key = <<-END
-----BEGIN RSA PRIVATE KEY-----
-----END RSA PRIVATE KEY-----
END

# Use git to download source
# Verify if source was already downloaded (idempontent) or if DB being restored is already restored?

#SshWrapper.generate(:user=>"root", :group=>"root", :prefix=>"/tmp/foo", :private_key=>"ssh private key")

# Create private key file
file "/tmp/private_key" do
  owner "root"
  group "root"
  mode "0700"
  content ssh_private_key
  action :create
end

# Create bash script to use for GIT_SSH
bash_script = <<-END
exec ssh -o StrictHostKeyChecking=no -i /tmp/private_key "$@"
END

file "/tmp/git_ssh.sh" do
  owner "root"
  group "root"
  mode "0700"
  content bash_script
  action :create
end

git "/tmp/info" do
  repository "git@github.com:rightscale/examples.git"
  revision "unified_php"
  ssh_wrapper "/tmp/git_ssh.sh"
end


#dump_file = node['rs-mysql']['import']['dump_file']
#node['rs-mysql']['import']['repository']
#node['rs-mysql']['import']['revision']

=begin
if dump_file && !dump_file.empty?
  dump_file = "/usr/local/www/sites/#{node['rs-application_php']['application_name']}/current/#{dump_file}"
  touch_file = "/var/lib/rightscale/rs-mysql-#{::File.basename(dump_file)}.touch"

  if ::File.exists?(touch_file)
    log "The dump file was already imported at #{::File.ctime(touch_file)}"
  else
    case dump_file
    when /\.gz$/
      uncompress_command = "gunzip --stdout '#{dump_file}'"
    when /\.bz2$/
      uncompress_command = "bunzip2 --stdout '#{dump_file}'"
    when /\.xz$/
      uncompress_command = "xz --decompress --stdout '#{dump_file}'"
    end

    # The connection hash to use to connect to MySQL
    mysql_connection_info = {
      :host => 'localhost',
      :username => 'root',
      :password => node['rs-mysql']['server_root_password']
    }

    # Import from MySQL dump
    mysql_database node['rs-mysql']['application_database_name'] do
      connection mysql_connection_info
      sql do
        if uncompress_command
          uncompress = Mixlib::ShellOut.new(uncompress_command).run_command
          uncompress.error!
          uncompress.stdout
        else
          ::File.read(dump_file)
        end
      end
      action :query
    end

    # Make sure directory /var/lib/rightscale exists which will contain the touch file
    directory '/var/lib/rightscale' do
      mode 0755
      action :create
    end

    # Create a touch file containing the name of the dump file so this action can be skipped if the
    # recipe is run with the same input multiple times.
    file touch_file do
      action :touch
    end
  end
end
=end

