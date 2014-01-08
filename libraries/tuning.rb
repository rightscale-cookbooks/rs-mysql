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

module RsMysql
  module Tuning
    def self.calculate_mysql_tuning_attributes(node_tuning, memory_str, server_usage)
      factor =
        if server_usage == 'dedicated'
          1
        else
          0.5
        end
      memory = calculate_system_memory(memory_str)
      node_tuning['query_cache_size'] = value_with_units((memory * 0.01).to_i, 'M', factor)
      node_tuning['innodb_buffer_pool_size'] = value_with_units((memory * 0.8).to_i, 'M', factor)
      node_tuning['thread_cache_size'] = (50 * factor).to_i
    end

    def self.calculate_system_memory(memory_str)
      # TODO: Fix meeeee please
      memory_str.to_i / 1024
    end

    def self.value_with_units(value, unit, factor)
      raise 'Value must convert to an integer.' unless value.to_i
      raise 'Units must be k, K, m, M, g, G' unless unit =~ /[KMG]/i
      raise "Factor must be between 1.0 and 0.0. You gave: #{factor}" if factor > 1.0 || factor < 0.0
      "#{(value * factor)}#{unit}"
    end
  end
end
