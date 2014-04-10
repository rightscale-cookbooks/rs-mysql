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
    # @raise [RuntimeError] if the IP address type is not either 'public' or 'private' or
    #   if an IP of a particular type cannot be found
    #
    def self.get_bind_ip_address(node)
      case node['rs-mysql']['bind_ip_type']
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
        raise "Unknown IP address type '#{node['rs-mysql']['bind_ip_type']}'!" +
          " The IP address type must be either 'public' or 'private'."
      end
    end

    # Performs a mysql query as the root user and returns the output of the query.
    #
    # @param hostname [String] the hostname of server to connect to mysql against
    # @param password [String] the password for the root mysql user
    # @param query_string [String] the mysql query string to run
    #
    # @return [Hash{String=>String}] the output of the mysql query
    #
    # @example Example usage
    #     RsMysql::Helper.query('localhost', 'rootpass', 'SELECT column1, column2 FROM dbname.tablename LIMIT 1')
    #     > {"column1" => "Data from column1", "column2" => "Data from column2"}
    #
    def self.query(hostname, password, query_string)
      require 'mysql'
      con = Mysql.new(hostname, 'root', password)
      Chef::Log.info "Performing query #{query_string} on #{hostname}..."
      result = con.query(query_string)
      result.fetch_hash if result
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
  end
end
