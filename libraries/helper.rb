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

    # Performs a mysql query and returns the output of the query.
    #
    # @param connection_info [Hash{Symbol, String}] MySQL connection information
    # @param query_string [String] the mysql query string to run
    #
    # @return [Hash{String=>String}] the output of the mysql query
    #
    # @example Example usage
    #     connection_info {
    #       host: 'localhost',
    #       username: 'root',
    #       password: 'rootpass',
    #     }
    #     RsMysql::Helper.query(connection_info, 'SELECT column1, column2 FROM dbname.tablename LIMIT 1')
    #     > {"column1" => "Data from column1", "column2" => "Data from column2"}
    #
    def self.query(connection_info, query_string)
      require 'mysql'
      con = Mysql.new(connection_info[:host], connection_info[:username], connection_info[:password])
      Chef::Log.info "Performing query #{query_string} on #{connection_info[:host]}..."
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
        Timeout.timeout(timeout) do
          slave_status = nil
          loop do
            Chef::Log.info 'Waiting for slave to become functional...'
            # Only sleep after the initial query
            sleep 2 if slave_status
            slave_status = query(connection_info, 'SHOW SLAVE STATUS')
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
