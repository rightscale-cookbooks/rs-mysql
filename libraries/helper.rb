#
# Cookbook Name:: rs-mysql
# Library:: helper
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

require 'ipaddr'
require 'socket'
require 'mixlib/shellout'

module RsMysql
  module Helper
    extend Chef::Mixin::ShellOut

    # Gets the IP address that the MySQL server will bind to. If `node['rs-mysql']['bind_address']` is set to an IP
    # address or host name, the IP address value of the attribute will be used instead.
    #
    # @param node [Chef::Node] the chef node
    #
    # @return [String] the bind IP address
    #
    # @raise [RuntimeError] if the network interface is not either 'public' or 'private' or
    #   if an IP of a particular network interface could not be found
    #
    def self.get_bind_ip_address(node)
      if node['rs-mysql']['bind_address']
        Addrinfo.getaddrinfo(node['rs-mysql']['bind_address'], nil, Socket::PF_INET).first.ip_address
      else
        case node['rs-mysql']['bind_network_interface']
        when 'private'
          priv_ip = nil
          if !node['cloud']['private_ips'].nil? && !node['cloud']['private_ips'].empty?
            priv_ip = node['cloud']['private_ips'].first
          end

          if !node['cloud_v2']['local_ipv4_addrs'].nil? && !node['cloud_v2']['local_ipv4_addrs'].empty? && priv_ip.nil?
            priv_ip = node['cloud_v2']['local_ipv4_addrs'].first
          end

          if priv_ip.nil? && IPAddress(node['ipaddress']).private?
            priv_ip = node['ipaddress']
          end

          raise 'Cannot find private IP of the server!' if priv_ip.nil?

          priv_ip
        when 'public'
          public_ip = nil
          if !node['cloud']['public_ips'].nil? && !node['cloud']['public_ips'].empty?
            public_ip = node['cloud']['public_ips'].first
          end

          if !node['cloud_v2']['public_ipv4_addrs'].nil? && !node['cloud_v2']['public_ipv4_addrs'].empty? && public_ip.nil?
            public_ip = node['cloud_v2']['public_ipv4_addrs'].first
          end

          if public_ip.nil? && !IPAddress(node['ipaddress']).private?
            public_ip = node['ipaddress']
          end

          raise 'Cannot find public IP of the server!' if public_ip.nil?

          public_ip
        else
          raise "Unknown network interface '#{node['rs-mysql']['bind_network_interface']}'!" \
                " The network interface must be either 'public' or 'private'."
        end
      end
    end

    # Finds the missing DNS credentials to set DNS entry for a MySQL server.
    #
    # @param node [Chef::Node] the chef node
    #
    # @return [Array] the missing DNS credentials
    #
    def self.find_missing_dns_credentials(node)
      missing_creds = []

      %w(master_fqdn user_key secret_key).each do |cred|
        unless node['rs-mysql']['dns'][cred] && !node['rs-mysql']['dns'][cred].empty?
          missing_creds << cred
        end
      end

      missing_creds
    end

    # Verifies that the server has come operational after start/restart
    def self.verify_mysqld_is_up(connection_info, timeout = 300)
      Chef::Log.info "Timeout is set to: #{timeout.inspect}"
      # Verify slave functional only if timeout is a positive value
      if timeout && timeout > 0
        Timeout.timeout(timeout) do
          @ping_result = ''
          while @ping_result != 'mysqld is alive'
            ping = Mixlib::ShellOut.new("mysqladmin ping -h #{connection_info[:host]} -u #{connection_info[:username]} -p#{connection_info[:password]}").run_command
            @ping_result = ping.stdout.strip
            Chef::Log.info "Result STDOUT: #{ping.stdout}, STDERR: #{ping.stderr}"
            sleep 10
          end
        end
      else
        Chef::Log.info 'Skipping mysql check as timeout is too low'
      end
    end

    # Verifies if the slave server is functional by checking the 'Slave_IO_Running' and 'Slave_SQL_Running' in the
    # output of SHOW SLAVE STATUS query. This verification is done with a sleep of 2 seconds and a configurable
    # timeout.
    #
    # @param connection_info [Hash{Symbol, String}] MySQL connection information
    # @param timeout [Integer] the number of seconds to use for timeout
    #
    # @raise [Timeout::Error] if the slave is not functional after the specified timeout
    #
    def self.verify_slave_functional(connection_info, timeout)
      Chef::Log.info "Timeout is set to: #{timeout.inspect}"
      # Verify slave functional only if timeout is a positive value
      if timeout && timeout < 0
        Chef::Log.info 'Skipping slave verification as timeout is set to a negative value'
      else
        require 'mysql2'

        with_closing(Mysql2::Client.new(connection_info)) do |connection|
          Timeout.timeout(timeout) do
            slave_status = nil
            loop do
              Chef::Log.info 'Waiting for slave to become functional...'
              # Only sleep after the initial query
              sleep 2 if slave_status
              slave_status = connection.query('SHOW SLAVE STATUS', as: :hash, symbolize_keys: false).first
              break if slave_status['Slave_IO_Running'] == 'Yes' && slave_status['Slave_SQL_Running'] == 'Yes'
            end
          end
        end
      end
    end

    # Waits for slaves to finish reading relay logs before switching the master or promoting.
    #
    # @param connection_info [Hash{Symbol, String}] MySQL connection information
    #
    def self.wait_for_relay_log_read(connection_info)
      Chef::Log.info 'Waiting for slave to read relay log...'

      require 'mysql2'

      with_closing(Mysql2::Client.new(connection_info)) do |connection|
        slave_status = connection.query('SHOW SLAVE STATUS').first

        Chef::Log.info "Slave IO state: #{(slave_status && slave_status['Slave_IO_State']).inspect}"

        if slave_status && slave_status['Slave_IO_State'] != ''
          loop do
            read_all = false
            connection.query('SHOW PROCESSLIST').each_hash do |item|
              Chef::Log.info "Process state: #{item['Id']}: #{item['State'].inspect}"

              if item['State'] =~ /has read all relay log/i
                read_all = true
                break
              end
            end
            break if read_all
            sleep 2
          end
        end
      end

      Chef::Log.info 'Slave relay log read.'
    end

    # Get the MySQL master info for use in backups.
    #
    # @param connection_info [Hash{Symbol, String}] MySQL connection information
    #
    # @return [Hash{Symbol => String}] MySQL master info, `:file` is the MySQL binlog file and `:position` is the MySQL
    #   binlog position
    #
    def self.get_master_info(connection_info)
      require 'mysql2'

      with_closing(Mysql2::Client.new(connection_info)) do |connection|
        master_status = connection.query('SHOW MASTER STATUS', as: :hash, symbolize_keys: false).first
        slave_status = connection.query('SHOW SLAVE STATUS', as: :hash, symbolize_keys: false).first

        master_info = if slave_status
                        {
                          file: slave_status['Relay_Master_Log_File'],
                          position: slave_status['Exec_Master_Log_Pos']
                        }
                      elsif master_status
                        {
                          file: master_status['File'],
                          position: master_status['Position']
                        }
                      else
                        {}
                      end

        master_info
      end
    end

    # Get the MySQL master info for use in backups.
    #
    # @param connection_info [Hash{Symbol, String}] MySQL connection information
    #
    # @return [Hash{Symbol => String}] MySQL master info, `:file` is the MySQL binlog file and `:position` is the MySQL
    #   binlog position
    #
    # @see .get_master_info
    #
    def get_master_info(connection_info)
      RsMysql::Helper.get_master_info(connection_info)
    end

    # Given a mount point this method will inspect if an LVM is used for the device mounted at the mount point.
    #
    # @param mount_point [String] the mount point of the device
    #
    # @return [Boolean] whether LVM is used in the device at the mount point
    #
    def self.is_lvm_used?(mount_point)
      mount = shell_out!('mount')
      mount.stdout.each_line do |line|
        if line =~ /^(.+)\s+on\s+#{mount_point}\s+/
          device = Regexp.last_match(1)
          return !!(device =~ /^\/dev\/mapper/) && shell_out("lvdisplay '#{device}'").status == 0
        end
      end
      false
    end

    # Given a mount point this method will inspect if an LVM is used for the device mounted at the mount point.
    #
    # @param mount_point [String] the mount point of the device
    #
    # @return [Boolean] whether LVM is used in the device at the mount point
    #
    # @see .is_lvm_used?
    #
    def is_lvm_used?(mount_point)
      RsMysql::Helper.is_lvm_used?(mount_point)
    end

    # Removes the LVM conditionally. It only accepts the name of the volume group and performs the following:
    # 1. Removes the logical volumes in the volume group
    # 2. Removes the volume group itself
    # 3. Removes the physical volumes used to create the volume group
    #
    # This method is also idempotent -- it simply exits if the volume group is already removed.
    #
    # @param volume_group_name [String] the name of the volume group
    #
    def self.remove_lvm(volume_group_name)
      require 'lvm'
      lvm = LVM::LVM.new
      volume_group = lvm.volume_groups[volume_group_name]
      if volume_group.nil?
        Chef::Log.info "Volume group '#{volume_group_name}' is not found"
      else
        logical_volume_names = volume_group.logical_volumes.map(&:name)
        physical_volume_names = volume_group.physical_volumes.map(&:name)

        # Remove the logical volumes
        logical_volume_names.each do |logical_volume_name|
          Chef::Log.info "Removing logical volume '#{logical_volume_name}'"
          command = "lvremove --force /dev/mapper/#{to_dm_name(volume_group_name)}-#{to_dm_name(logical_volume_name)}"
          Chef::Log.debug "Running command: '#{command}'"
          output = lvm.raw(command)
          Chef::Log.debug "Command output: #{output}"
        end

        # Remove the volume group
        Chef::Log.info "Removing volume group '#{volume_group_name}'"
        command = "vgremove #{volume_group_name}"
        Chef::Log.debug "Running command: #{command}"
        output = lvm.raw(command)
        Chef::Log.debug "Command output: #{output}"

        physical_volume_names.each do |physical_volume_name|
          Chef::Log.info "Removing physical volume '#{physical_volume_name}'"
          command = "pvremove #{physical_volume_name}"
          Chef::Log.debug "Running command: #{command}"
          output = lvm.raw(command)
          Chef::Log.debug "Command output: #{output}"
        end
      end
    end

    # Removes the LVM conditionally. It only accepts the name of the volume group and performs the following:
    # 1. Removes the logical volumes in the volume group
    # 2. Removes the volume group itself
    # 3. Removes the physical volumes used to create the volume group
    #
    # This method is also idempotent -- it simply exits if the volume group is already removed.
    #
    # @param volume_group_name [String] the name of the volume group
    #
    # @see .remove_lvm
    #
    def remove_lvm(volume_group_name)
      RsMysql::Helper.remove_lvm(volume_group_name)
    end

    # Replaces dashes (-) with double dashes (--) to mimic the behavior of the LVM cookbook's naming convention of
    # naming logical volume names.
    #
    # @param name [String] the name to be converted
    #
    # @return [String] the converted name
    #
    def self.to_dm_name(name)
      name.gsub(/-/, '--')
    end

    # Replaces dashes (-) with double dashes (--) to mimic the behavior of the LVM cookbook's naming convention of
    # naming logical volume names.
    #
    # @param name [String] the name to be converted
    #
    # @return [String] the converted name
    #
    # @see .to_dm_name
    #
    def to_dm_name(name)
      RsMysql::Helper.to_dm_name(name)
    end

    private

    # Run a block with an object and call its `close` method when finished.
    #
    # @param object [#close] the object to use and close when done
    # @param block [Proc(Object)] the block which will use the object
    #
    # @return [Object] the value returned by the block
    #
    def self.with_closing(object, &block)
      block.call(object)
    ensure
      object.close
    end
  end
end

# Include this helper to recipes
::Chef::Recipe.send(:include, RsMysql::Helper)
::Chef::Resource::RubyBlock.send(:include, RsMysql::Helper)
::Chef::Resource::File.send(:include, RsMysql::Helper)
