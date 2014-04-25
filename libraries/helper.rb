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

module RsMysql
  module Helper
    extend Chef::Mixin::ShellOut

    # Gets the first public IP address of the server if present, or else
    # returns its first private IP address.
    #
    # @param node [Chef::Node] the chef node
    #
    # @return [IPAddr] the IP address of the server
    #
    def self.get_server_ip(node)
      if node['cloud']['public_ips'] && !node['cloud']['public_ips'].empty?
        IPAddr.new(node['cloud']['public_ips'].first)
      else
        IPAddr.new(node['cloud']['private_ips'].first)
      end
    end

    # Gets the IP address that the MySQL server will bind to.
    #
    # @param node [Chef::Node] the chef node
    #
    # @return [String] the bind IP address
    #
    # @raise [RuntimeError] if the network interface is not either 'public' or 'private' or
    #   if an IP of a particular network interface could not be found
    #
    def self.get_bind_ip_address(node)
      case node['rs-mysql']['bind_network_interface']
      when "private"
        if node['cloud']['private_ips'].nil? || node['cloud']['private_ips'].empty?
          raise 'Cannot find private IP of the server!'
        end

        node['cloud']['private_ips'].first
      when "public"
        if node['cloud']['public_ips'].nil? || node['cloud']['public_ips'].empty?
          raise 'Cannot find public IP of the server!'
        end

        node['cloud']['public_ips'].first
      else
        raise "Unknown network interface '#{node['rs-mysql']['bind_network_interface']}'!" +
          " The network interface must be either 'public' or 'private'."
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

      ['master_fqdn', 'user_key', 'secret_key'].each do |cred|
        unless node['rs-mysql']['dns'][cred] && !node['rs-mysql']['dns'][cred].empty?
          missing_creds << cred
        end
      end

      missing_creds
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
        require 'mysql'
        connection = Mysql.new(connection_info[:host], connection_info[:username], connection_info[:password])

        Timeout.timeout(timeout) do
          slave_status = nil
          loop do
            Chef::Log.info 'Waiting for slave to become functional...'
            # Only sleep after the initial query
            sleep 2 if slave_status
            slave_status = connection.query('SHOW SLAVE STATUS').fetch_hash
            break if slave_status["Slave_IO_Running"] == "Yes" && slave_status["Slave_SQL_Running"] == "Yes"
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

      require 'mysql'
      connection = Mysql.new(connection_info[:host], connection_info[:username], connection_info[:password])
      slave_status = connection.query('SHOW SLAVE STATUS').fetch_hash

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
      require 'mysql'
      connection = Mysql.new(connection_info[:host], connection_info[:username], connection_info[:password])
      master_status = connection.query('SHOW MASTER STATUS').fetch_hash
      slave_status = connection.query('SHOW SLAVE STATUS').fetch_hash

      if slave_status
        master_info = {
          file: slave_status['Relay_Master_Log_File'],
          position: slave_status['Exec_Master_Log_Pos'],
        }
      elsif master_status
        master_info = {
          file: master_status['File'],
          position: master_status['Position'],
        }
      else
        master_info = {}
      end

      master_info
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
          device = $1
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
        logical_volume_names = volume_group.logical_volumes.map { |logical_volume| logical_volume.name }
        physical_volume_names = volume_group.physical_volumes.map { |physical_volume| physical_volume.name }

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

    # Obtains the run state of the server. It uses the `rs_state` utility to get the current system run state.
    # Possible values for this command:
    # - booting
    # - booting:reboot
    # - operational
    # - stranded
    # - shutting-down:reboot
    # - shutting-down:terminate
    # - shutting-down:stop
    #
    # @return [String] the current system run state
    #
    def self.get_rs_run_state
      state = shell_out!('rs_state --type=run')
      state.stdout.chomp
    end

    # Obtains the run state of the server. It uses the `rs_state` utility to get the current system run state.
    # Possible values for this command:
    # - booting
    # - booting:reboot
    # - operational
    # - stranded
    # - shutting-down:reboot
    # - shutting-down:terminate
    # - shutting-down:stop
    #
    # @return [String] the current system run state
    #
    # @see .get_rs_run_state
    #
    def get_rs_run_state
      RsMysql::Helper.get_rs_run_state
    end
  end
end

# Include this helper to recipes
::Chef::Recipe.send(:include, RsMysql::Helper)
::Chef::Resource::RubyBlock.send(:include, RsMysql::Helper)
::Chef::Resource::File.send(:include, RsMysql::Helper)
