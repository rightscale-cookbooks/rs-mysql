#
# Cookbook Name:: rs-mysql
# Library:: tuning
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

# The top level module for helpers in this cookbook.
module RsMysql
  # The helper for calculating the MySQL tuning attributes.
  module Tuning

    # The constant to multiple memory (in megabypes) to obtain the gigabytes value.
    GB = 1024

    # Tunes the MySQL attributes based on the available memory and server usage type.
    #
    # @param node_tuning [Chef::Node] the chef node containing the MySQL tuning attributes
    # @param memory [String, Integer] the total available system memory
    # @param server_usage [String, Symbol] the server usage type. should be `'dedicated'` or `'shared'`
    #
    def self.tune_attributes(node_tuning, memory, server_usage)
      factor = server_usage.to_s == 'dedicated' ? 1 : 0.5
      memory = memory_in_megabytes(memory)
      node_tuning['query_cache_size'] = value_with_units((memory * factor * 0.01).to_i, 'M')
      node_tuning['innodb_buffer_pool_size'] = value_with_units((memory * factor * 0.8).to_i, 'M')

      # Fixed parameters, common value for all memory categories.
      #
      node_tuning['thread_cache_size'] = (50 * factor).to_i
      node_tuning['max_connections'] = (800 * factor).to_i
      node_tuning['wait_timeout'] = (28800 * factor).to_i
      node_tuning['net_read_timeout'] = (30 * factor).to_i
      node_tuning['net_write_timeout'] = (30 * factor).to_i
      node_tuning['back_log'] = (128 * factor).to_i
      node_tuning['max_heap_table_size'] = value_with_units((32 * factor).to_i, 'M')
      node_tuning['read_buffer_size'] = value_with_units((1 * factor).to_i, 'M')
      node_tuning['read_rnd_buffer_size'] = value_with_units((4 * factor).to_i, 'M')
      node_tuning['long_query_time'] = 5

      # Sets buffer sizes and InnoDB log properties. Overrides buffer sizes for really small servers.
      #
      if memory < 1 * GB
        node_tuning['key_buffer_size'] = value_with_units((16 * factor).to_i, 'M')
        node_tuning['max_allowed_packet'] = value_with_units((20 * factor).to_i, 'M')
        node_tuning['innodb_log_file_size'] = value_with_units((4 * factor).to_i, 'M')
        node_tuning['innodb_log_buffer_size'] = value_with_units((16 * factor).to_i, 'M')
      else
        node_tuning['key_buffer_size'] = value_with_units((128 * factor).to_i, 'M')
        node_tuning['max_allowed_packet'] = value_with_units((128 * factor).to_i, 'M')
        node_tuning['innodb_log_file_size'] = value_with_units((64 * factor).to_i, 'M')
        node_tuning['innodb_log_buffer_size'] = value_with_units((8 * factor).to_i, 'M')
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
        node_tuning['sort_buffer_size'] = value_with_units((2 * factor).to_i, 'M')
        node_tuning['innodb_additional_mem_pool_size'] = value_with_units((50 * factor).to_i, 'M')
        node_tuning['myisam_sort_buffer_size'] = value_with_units((64 * factor).to_i, 'M')
      elsif memory < 10 * GB
        node_tuning['table_open_cache'] = (512 * factor).to_i
        node_tuning['sort_buffer_size'] = value_with_units((4 * factor).to_i, 'M')
        node_tuning['innodb_additional_mem_pool_size'] = value_with_units((200 * factor).to_i, 'M')
        node_tuning['myisam_sort_buffer_size'] = value_with_units((96 * factor).to_i, 'M')
      elsif memory < 25 * GB
        node_tuning['table_open_cache'] = (1024 * factor).to_i
        node_tuning['sort_buffer_size'] = value_with_units((8 * factor).to_i, 'M')
        node_tuning['innodb_additional_mem_pool_size'] = value_with_units((300 * factor).to_i, 'M')
        node_tuning['myisam_sort_buffer_size'] = value_with_units((128 * factor).to_i, 'M')
      elsif memory < 50 * GB
        node_tuning['table_open_cache'] = (2048 * factor).to_i
        node_tuning['sort_buffer_size'] = value_with_units((16 * factor).to_i, 'M')
        node_tuning['innodb_additional_mem_pool_size'] = value_with_units((400 * factor).to_i, 'M')
        node_tuning['myisam_sort_buffer_size'] = value_with_units((256 * factor).to_i, 'M')
      else
        node_tuning['table_open_cache'] = (4096 * factor).to_i
        node_tuning['sort_buffer_size'] = value_with_units((32 * factor).to_i, 'M')
        node_tuning['innodb_additional_mem_pool_size'] = value_with_units((500 * factor).to_i, 'M')
        node_tuning['myisam_sort_buffer_size'] = value_with_units((512 * factor).to_i, 'M')
      end
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
      # If ohai returns the total memory in String, it will most likely be in kB.
      if memory.is_a?(String) && memory =~ /\d+kB/i
        memory.to_i / 1024
      # If it returns an integer, it will most likely be in bytes.
      else
        memory / (1024 * 1024)
      end
    end

    # Given the value, unit, this method will return the value with the unit.
    #
    # @param value [Integer] the value of a tunable attribute
    # @param unit [String] the unit. Should be one of `'k'`, `'K'`, `'m'`, `'M'`, `'g'`, `'G'`.
    #
    # @return [String] the value with the unit.
    #
    # @example An Example
    #   >> value_with_units(8, 'M')
    #   => '8M'
    #
    def self.value_with_units(value, unit)
      "#{value}#{unit}"
    end
  end
end
