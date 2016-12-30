user 'mysql_monitor' do
  action :create
end

service 'collectd' do
  action :stop
end

template '/usr/local/bin/mysql_seconds_behind_master.rb' do
  source 'mysql_seconds_behind_master.rb.erb'
  owner 'root'
  group 'root'
  mode 0755
  action :create
end

node.set['rs-mysql']['exec'] = ['Exec "mysql_monitor" "/opt/chef/embedded/bin/ruby" "/usr/local/bin/mysql_seconds_behind_master.rb"']

template '/usr/local/bin/mysql_slave_running.rb' do
  source 'mysql_slave_running.rb.erb'
  owner 'root'
  group 'root'
  mode 0755
  action :create
end

node.set['rs-mysql']['exec'] << 'Exec "mysql_monitor" "/opt/chef/embedded/bin/ruby" "/usr/local/bin/mysql_slave_running.rb"'

template ::File.join(node['collectd']['service']['config_directory'], 'exec.conf') do
  source 'exec.conf.erb'
  owner 'root'
  group 'root'
  mode 0755
  action :create
end

service 'collectd' do
  action :start
end
