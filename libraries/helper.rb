#
# Cookbook Name:: rs-mysql
# Library:: helper
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
    # @param hostname [String] the hostname of server to connect to mysql against
    # @param password [String] the password for the root mysql user
    # @param query_string [String] the mysql query string to run
    #
    # @return [Hash{String=>String}] the output of the mysql query
    #
    # @example Example usage
    #     RsMysql::Helper.query('localhost', 'rootpass', 'SHOW SLAVE STATUS')
    #     > {"Slave_IO_State"=>"Waiting for master to send event", ... }
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
    # @param hostname [String] the hostname of the server to connect to mysql against
    # @param password [String] the password of the root mysql user
    # @param timeout [Integer] the number of seconds to use for timeout
    #
    # @raise [Timeout::Error] if the slave is not functional after the specified timeout
    #
    def self.verify_slave_functional(hostname, password, timeout)
      Chef::Log.info "Timeout is set to: #{timeout.inspect}"
      # Verify slave functional only if timeout is a positive value
      if timeout && timeout < 0
        Chef::Log.info 'Skipping slave verification as timeout is set to a negative value'
      else
        Timeout.timeout(timeout) do
          slave_status = query(hostname, password, 'SHOW SLAVE STATUS')
          until slave_status["Slave_IO_Running"] == "Yes" && slave_status["Slave_SQL_Running"] == "Yes"
            Chef::Log.info 'Waiting for slave to become functional...'
            sleep 2
            slave_status = query(hostname, password, 'SHOW SLAVE STATUS')
          end
        end
      end
    end
  end
end
