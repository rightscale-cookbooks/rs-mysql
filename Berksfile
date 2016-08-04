#site :opscode
source "https://supermarket.chef.io"

metadata

cookbook 'collectd', github: 'rightscale-cookbooks-contrib/chef-collectd', branch: 'generalize_install_for_both_centos_and_ubuntu'
cookbook 'mysql', github: 'rightscale-cookbooks-contrib/mysql', branch: 'rs-fixes'
cookbook 'dns', github: 'rightscale-cookbooks-contrib/dns', branch: 'rightscale_development_v2'
cookbook 'build-essential', '~> 1.4'
cookbook 'database', github: 'rightscale-cookbooks-contrib/database', branch: 'rs-fixes'

cookbook 'rightscale_backup',github: 'rightscale-cookbooks/rightscale_backup', branch: 'v1.2.0'
cookbook 'rightscale_volume',github: 'rightscale-cookbooks/rightscale_volume', branch: 'v1.3.0'
cookbook 'rightscale_tag',github: 'rightscale-cookbooks/rightscale_tag', branch: 'v1.1.0'
cookbook 'machine_tag',github: 'rightscale-cookbooks/machine_tag', branch: 'v1.1.0'
cookbook 'ephemeral_lvm',github:'rightscale-cookbooks/ephemeral_lvm', branch: 'v1.0.15'
cookbook 'ohai', '= 2.1.0'

group :integration do
  cookbook 'runit', '1.6.0'
  cookbook 'apt', '~> 2.9.2'
  cookbook 'yum-epel', '~> 0.4.0'
  cookbook 'curl', '~> 1.1.0'
  cookbook 'fake', path: './test/cookbooks/fake'
  cookbook 'rhsm', '~> 1.0.0'
end
