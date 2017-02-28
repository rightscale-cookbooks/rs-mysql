# frozen_string_literal: true
#
# Cookbook Name:: mysql
# Attributes:: server
#
# Copyright 2008-2013, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Probably driven from wrapper cookbooks, environments, or roles.
# Keep in this namespace for backwards compat

# actual configs start here
default['rs-mysql']['tunable']['character-set-server'] = 'utf8'
default['rs-mysql']['tunable']['collation-server']     = 'utf8_general_ci'
default['rs-mysql']['tunable']['lower_case_table_names'] = nil
default['rs-mysql']['tunable']['back_log'] = '128'
default['rs-mysql']['tunable']['key_buffer_size']           = '256M'
default['rs-mysql']['tunable']['myisam_sort_buffer_size']   = '8M'
default['rs-mysql']['tunable']['myisam_max_sort_file_size'] = '2147483648'
default['rs-mysql']['tunable']['myisam_repair_threads']     = '1'
default['rs-mysql']['tunable']['myisam-recover']            = 'BACKUP'
default['rs-mysql']['tunable']['max_allowed_packet']   = '16M'
default['rs-mysql']['tunable']['max_connections']      = '800'
default['rs-mysql']['tunable']['max_connect_errors']   = '10'
default['rs-mysql']['tunable']['concurrent_insert']    = '2'
default['rs-mysql']['tunable']['connect_timeout']      = '10'
default['rs-mysql']['tunable']['tmp_table_size']       = '32M'
default['rs-mysql']['tunable']['max_heap_table_size']  = node['rs-mysql']['tunable']['tmp_table_size']
default['rs-mysql']['tunable']['bulk_insert_buffer_size'] = node['rs-mysql']['tunable']['tmp_table_size']
default['rs-mysql']['tunable']['net_read_timeout']     = '30'
default['rs-mysql']['tunable']['net_write_timeout']    = '30'
default['rs-mysql']['tunable']['table_cache']          = '128' if node['rs-mysql']['mysql']['version'] < '5.5'
default['rs-mysql']['tunable']['table_open_cache']     = '128' if node['rs-mysql']['mysql']['version'] > '5.5'
# in favor of table_open_cache
default['rs-mysql']['tunable']['thread_cache_size']    = 8
default['rs-mysql']['tunable']['thread_concurrency']   = 10
default['rs-mysql']['tunable']['thread_stack']         = '256K'
default['rs-mysql']['tunable']['sort_buffer_size']     = '2M'
default['rs-mysql']['tunable']['read_buffer_size']     = '128k'
default['rs-mysql']['tunable']['read_rnd_buffer_size'] = '256k'
default['rs-mysql']['tunable']['join_buffer_size']     = '128k'
default['rs-mysql']['tunable']['wait_timeout']         = '180'
default['rs-mysql']['tunable']['open-files-limit']     = '1024'

default['rs-mysql']['tunable']['sql_mode'] = nil

default['rs-mysql']['tunable']['skip-character-set-client-handshake'] = false
default['rs-mysql']['tunable']['skip-name-resolve']                   = false

default['rs-mysql']['tunable']['slave_compressed_protocol']       = 0

default['rs-mysql']['tunable']['server_id']                       = nil
default['rs-mysql']['tunable']['log_bin']                         = nil
default['rs-mysql']['tunable']['log_bin_trust_function_creators'] = false

default['rs-mysql']['tunable']['relay_log']                       = nil
default['rs-mysql']['tunable']['relay_log_index']                 = nil
default['rs-mysql']['tunable']['log_slave_updates']               = false

default['rs-mysql']['tunable']['replicate_do_db']             = nil
default['rs-mysql']['tunable']['replicate_do_table']          = nil
default['rs-mysql']['tunable']['replicate_ignore_db']         = nil
default['rs-mysql']['tunable']['replicate_ignore_table']      = nil
default['rs-mysql']['tunable']['replicate_wild_do_table']     = nil
default['rs-mysql']['tunable']['replicate_wild_ignore_table'] = nil

default['rs-mysql']['tunable']['sync_binlog']                     = 0
default['rs-mysql']['tunable']['skip_slave_start']                = false
default['rs-mysql']['tunable']['read_only']                       = false

default['rs-mysql']['tunable']['log_error']                       = nil
default['rs-mysql']['tunable']['log_warnings']                    = false
default['rs-mysql']['tunable']['log_queries_not_using_index']     = true
default['rs-mysql']['tunable']['log_bin_trust_function_creators'] = false

default['rs-mysql']['tunable']['innodb_log_file_size']            = '5M'
default['rs-mysql']['tunable']['innodb_buffer_pool_size']         = '128M'
default['rs-mysql']['tunable']['innodb_buffer_pool_instances']    = '4'
default['rs-mysql']['tunable']['innodb_additional_mem_pool_size'] = '8M'
default['rs-mysql']['tunable']['innodb_data_file_path']           = 'ibdata1:10M:autoextend'
default['rs-mysql']['tunable']['innodb_flush_method']             = false
default['rs-mysql']['tunable']['innodb_log_buffer_size']          = '8M'
default['rs-mysql']['tunable']['innodb_write_io_threads']         = '4'
default['rs-mysql']['tunable']['innodb_io_capacity']              = '200'
default['rs-mysql']['tunable']['innodb_file_per_table']           = true
default['rs-mysql']['tunable']['innodb_lock_wait_timeout']        = '60'
if node['cpu'].nil? || node['cpu']['total'].nil?
  default['rs-mysql']['tunable']['innodb_thread_concurrency']       = '8'
  default['rs-mysql']['tunable']['innodb_commit_concurrency']       = '8'
  default['rs-mysql']['tunable']['innodb_read_io_threads']          = '8'
else
  default['rs-mysql']['tunable']['innodb_thread_concurrency']       = (node['cpu']['total'].to_i * 2).to_s
  default['rs-mysql']['tunable']['innodb_commit_concurrency']       = (node['cpu']['total'].to_i * 2).to_s
  default['rs-mysql']['tunable']['innodb_read_io_threads']          = (node['cpu']['total'].to_i * 2).to_s
end
default['rs-mysql']['tunable']['innodb_flush_log_at_trx_commit']  = '1'
default['rs-mysql']['tunable']['innodb_support_xa']               = true
default['rs-mysql']['tunable']['innodb_table_locks']              = true
default['rs-mysql']['tunable']['skip-innodb-doublewrite']         = false

default['rs-mysql']['tunable']['transaction-isolation'] = nil

default['rs-mysql']['tunable']['query_cache_limit']    = '1M'
default['rs-mysql']['tunable']['query_cache_size']     = '16M'

default['rs-mysql']['tunable']['long_query_time']      = 2
default['rs-mysql']['tunable']['expire_logs_days']     = 10
default['rs-mysql']['tunable']['max_binlog_size']      = '100M'
default['rs-mysql']['tunable']['binlog_cache_size']    = '32K'

unless node['platform_family'] == 'rhel' && node['platform_version'].to_i < 6
  # older RHEL platforms don't support these options
  default['rs-mysql']['tunable']['event_scheduler']  = 0
  default['rs-mysql']['tunable']['binlog_format']    = 'statement' if node['rs-mysql']['tunable']['log_bin']
end
default['rs-mysql']['tunable']['innodb_adaptive_flushing'] = false
