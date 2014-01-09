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

module RsMysql
  module Tuning

    GB = 1024

    def self.tune_attributes(node_tuning, memory, server_usage)
      factor = server_usage.to_s == 'dedicated' ? 1 : 0.5
      memory = memory_in_megabytes(memory)
      node_tuning['query_cache_size'] = value_with_units((memory * 0.01).to_i, 'M', factor)
      node_tuning['innodb_buffer_pool_size'] = value_with_units((memory * 0.8).to_i, 'M', factor)

      # Fixed parameters, common value for all memory categories.
      #
      node_tuning['thread_cache_size'] = (50 * factor).to_i
      node_tuning['max_connections'] = (800 * factor).to_i
      node_tuning['wait_timeout'] = (28800 * factor).to_i
      node_tuning['net_read_timeout'] = (30 * factor).to_i
      node_tuning['net_write_timeout'] = (30 * factor).to_i
      node_tuning['back_log'] = (128 * factor).to_i
      node_tuning['max_heap_table_size'] = value_with_units(32, 'M', factor)
      node_tuning['read_buffer_size'] = value_with_units(1, 'M', factor)
      node_tuning['read_rnd_buffer_size'] = value_with_units(4, 'M', factor)
      node_tuning['long_query_time'] = 5

      # Sets buffer sizes and InnoDB log properties. Overrides buffer sizes for really small servers.
      #
      if memory < 1 * GB
        node_tuning['key_buffer'] = value_with_units(16, 'M', factor)
        node_tuning['max_allowed_packet'] = value_with_units(20, 'M', factor)
        node_tuning['innodb_log_file_size'] = value_with_units(4, 'M', factor)
        node_tuning['innodb_log_buffer_size'] = value_with_units(16, 'M', factor)
      else
        node_tuning['key_buffer'] = value_with_units(128, 'M', factor)
        node_tuning['max_allowed_packet'] = value_with_units(128, 'M', factor)
        node_tuning['innodb_log_file_size'] = value_with_units(64, 'M', factor)
        node_tuning['innodb_log_buffer_size'] = value_with_units(8, 'M', factor)
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
        node_tuning['sort_buffer_size'] = value_with_units(2, 'M', factor)
        node_tuning['innodb_additional_mem_pool_size'] = value_with_units(50, 'M', factor)
        node_tuning['myisam_sort_buffer_size'] = value_with_units(64, 'M', factor)
      elsif memory < 10 * GB
        node_tuning['table_open_cache'] = (512 * factor).to_i
        node_tuning['sort_buffer_size'] = value_with_units(4, 'M', factor)
        node_tuning['innodb_additional_mem_pool_size'] = value_with_units(200, 'M', factor)
        node_tuning['myisam_sort_buffer_size'] = value_with_units(96, 'M', factor)
      elsif memory < 25 * GB
        node_tuning['table_open_cache'] = (1024 * factor).to_i
        node_tuning['sort_buffer_size'] = value_with_units(8, 'M', factor)
        node_tuning['innodb_additional_mem_pool_size'] = value_with_units(300, 'M', factor)
        node_tuning['myisam_sort_buffer_size'] = value_with_units(128, 'M', factor)
      elsif memory < 50 * GB
        node_tuning['table_open_cache'] = (2048 * factor).to_i
        node_tuning['sort_buffer_size'] = value_with_units(16, 'M', factor)
        node_tuning['innodb_additional_mem_pool_size'] = value_with_units(400, 'M', factor)
        node_tuning['myisam_sort_buffer_size'] = value_with_units(256, 'M', factor)
      else
        node_tuning['table_open_cache'] = (4096 * factor).to_i
        node_tuning['sort_buffer_size'] = value_with_units(32, 'M', factor)
        node_tuning['innodb_additional_mem_pool_size'] = value_with_units(500, 'M', factor)
        node_tuning['myisam_sort_buffer_size'] = value_with_units(512, 'M', factor)
      end
    end

  private

    def self.memory_in_megabytes(memory)
      # If ohai returns the total memory in String, it will most likely be in kB.
      if memory.is_a?(String) && memory =~ /\d+kB/i
        memory.to_i / 1024
      # If it returns an integer, it will most likely be in bytes.
      elsif memory.is_a?(Integer)
        memory / (1024 * 1024)
      else
        nil
      end
    end

    def self.value_with_units(value, unit, factor)
      raise 'Value must convert to an integer.' unless value.to_i
      raise 'Units must be k, K, m, M, g, G' unless unit =~ /[KMG]/i
      raise "Factor must be between 1.0 and 0.0. You gave: #{factor}" if factor > 1.0 || factor < 0.0
      "#{(value * factor).to_i}#{unit}"
    end
  end
end
