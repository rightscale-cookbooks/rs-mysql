user 'mysql_monitor' do
  action :create
end

service 'collectd' do
  action :stop
end

bash 'clean up extra collectd processes' do
  flags "-ex"
  code <<-EOH
     while [ `pkill -c collectd` -gt 0 ]; do pkill -9 collectd; done
  EOH
  action :run
end

template '/usr/local/bin/mysql_seconds_behind_master.rb' do
  source 'mysql_seconds_behind_master.rb.erb'
  owner 'root'
  group 'root'
  mode 0755
  action :create
end

node.set['kabam-rs-mysql']['exec'] = ['Exec "mysql_monitor" "/opt/chef/embedded/bin/ruby" "/usr/local/bin/mysql_seconds_behind_master.rb"']

template '/usr/local/bin/mysql_slave_running.rb' do
  source 'mysql_slave_running.rb.erb'
  owner 'root'
  group 'root'
  mode 0755
  action :create
end

node.set['kabam-rs-mysql']['exec'] << 'Exec "mysql_monitor" "/opt/chef/embedded/bin/ruby" "/usr/local/bin/mysql_slave_running.rb"'

template ::File.join('/etc/collectd/plugins', 'exec.conf') do
  source 'exec.conf.erb'
  owner 'root'
  group 'root'
  mode 0755
  action :create
end

service 'collectd' do
  action :start
end
