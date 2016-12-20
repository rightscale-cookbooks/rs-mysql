#
# Cookbook Name:: rs-mysql
# Library:: tuning
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

# The top level module for helpers in this cookbook.
module RsMysql
  # The helper for calculating the MySQL tuning attributes.
  module Tuning
    # The constant multiplied with megabytes to obtain the value in gigabytes
    GB = 1024 unless const_defined?(:GB)

    # Tunes the MySQL attributes based on the available memory and server usage type.
    #
    # @param node_tuning [Chef::Node] the chef node containing the MySQL tuning attributes
    # @param memory [String, Integer] the total available system memory
    # @param server_usage [String, Symbol] the server usage type. should be `'dedicated'` or `'shared'`
    #
    def self.tune_attributes(node_tuning, memory, server_usage)
      factor = server_usage.to_s == 'dedicated' ? 1 : 0.5
      memory = memory_in_megabytes(memory)
      node_tuning['query_cache_size'] = (memory * factor * 0.01).to_i.to_s + 'M'
      node_tuning['innodb_buffer_pool_size'] = (memory * factor * 0.8).to_i.to_s + 'M'

      # Fixed parameters, common value for all memory categories.
      #
      node_tuning['thread_cache_size'] = (50 * factor).to_i
      node_tuning['max_connections'] = (800 * factor).to_i
      node_tuning['wait_timeout'] = (28_800 * factor).to_i
      node_tuning['net_read_timeout'] = (30 * factor).to_i
      node_tuning['net_write_timeout'] = (30 * factor).to_i
      node_tuning['back_log'] = (128 * factor).to_i
      node_tuning['max_heap_table_size'] = (32 * factor).to_i.to_s + 'M'
      node_tuning['read_buffer_size'] = (1 * factor).to_i.to_s + 'M'
      node_tuning['read_rnd_buffer_size'] = (4 * factor).to_i.to_s + 'M'
      node_tuning['long_query_time'] = 5

      # Sets buffer sizes and InnoDB log properties. Overrides buffer sizes for really small servers.
      #
      if memory < 1 * GB
        node_tuning['key_buffer_size'] = (16 * factor).to_i.to_s + 'M'
        node_tuning['max_allowed_packet'] = (20 * factor).to_i.to_s + 'M'
        node_tuning['innodb_log_file_size'] = (4 * factor).to_i.to_s + 'M'
        node_tuning['innodb_log_buffer_size'] = (16 * factor).to_i.to_s + 'M'
      else
        node_tuning['key_buffer_size'] = (128 * factor).to_i.to_s + 'M'
        node_tuning['max_allowed_packet'] = (128 * factor).to_i.to_s + 'M'
        node_tuning['innodb_log_file_size'] = (64 * factor).to_i.to_s + 'M'
        node_tuning['innodb_log_buffer_size'] = (8 * factor).to_i.to_s + 'M'
      end

      # Adjusts tunable values based on available system memory range.
      # The memory ranges used are:
      #   < 3 GB
      #   3 GB - 10 GB
      #   10 GB - 25 GB
      #   25 GB - 50 GB
      #   > 50 GB
      #
      if memory < 3 * GB
        node_tuning['table_open_cache'] = (256 * factor).to_i
        node_tuning['sort_buffer_size'] = (2 * factor).to_i.to_s + 'M'
        node_tuning['innodb_additional_mem_pool_size'] = (50 * factor).to_i.to_s + 'M'
        node_tuning['myisam_sort_buffer_size'] = (64 * factor).to_i.to_s + 'M'
      elsif memory < 10 * GB
        node_tuning['table_open_cache'] = (512 * factor).to_i
        node_tuning['sort_buffer_size'] = (4 * factor).to_i.to_s + 'M'
        node_tuning['innodb_additional_mem_pool_size'] = (200 * factor).to_i.to_s + 'M'
        node_tuning['myisam_sort_buffer_size'] = (96 * factor).to_i.to_s + 'M'
      elsif memory < 25 * GB
        node_tuning['table_open_cache'] = (1024 * factor).to_i
        node_tuning['sort_buffer_size'] = (8 * factor).to_i.to_s + 'M'
        node_tuning['innodb_additional_mem_pool_size'] = (300 * factor).to_i.to_s + 'M'
        node_tuning['myisam_sort_buffer_size'] = (128 * factor).to_i.to_s + 'M'
      elsif memory < 50 * GB
        node_tuning['table_open_cache'] = (2048 * factor).to_i
        node_tuning['sort_buffer_size'] = (16 * factor).to_i.to_s + 'M'
        node_tuning['innodb_additional_mem_pool_size'] = (400 * factor).to_i.to_s + 'M'
        node_tuning['myisam_sort_buffer_size'] = (256 * factor).to_i.to_s + 'M'
      else
        node_tuning['table_open_cache'] = (4096 * factor).to_i
        node_tuning['sort_buffer_size'] = (32 * factor).to_i.to_s + 'M'
        node_tuning['innodb_additional_mem_pool_size'] = (500 * factor).to_i.to_s + 'M'
        node_tuning['myisam_sort_buffer_size'] = (512 * factor).to_i.to_s + 'M'
      end
    end

    # Given a memory attribute in megabytes as a string, it will return the bytes equivalent.
    #
    # @param [String] attr the string attribute in megabytes
    #
    # @return [Integer] the value in bytes
    #
    def self.megabytes_to_bytes(attr)
      matched = attr.match(/(\d+)M/)
      matched[1].to_i * 1024 * 1024 if matched
    end

    private

    # Given the memory in either kilobytes as a String or in bytes as an Integer (the formats Ohai returns),
    # this method will return the memory in megabytes.
    #
    # @param memory [String, Integer] memory in kilobytes or bytes
    #
    # @return [Numeric] memory in megabytes
    #
    def self.memory_in_megabytes(memory)
      # If ohai returns the total memory in String, it is assumed to be in kB.
      if memory.is_a?(String) && memory =~ /\d+kB/i
        memory.to_i / 1024
      # If it returns an integer, it is assumed to be in bytes.
      else
        memory / (1024 * 1024)
      end
    end
  end
end
