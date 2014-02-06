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
  end
end
