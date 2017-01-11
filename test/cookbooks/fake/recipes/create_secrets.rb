directory '/var/run/rightlink' do
  owner 'root'
  group 'root'
  mode '0777'
  action :nothing
end.run_action(:create)

file '/var/run/rightlink/secret' do
  content 'RS_RLL_PORT=12345'
  action :nothing
end.run_action(:create)
