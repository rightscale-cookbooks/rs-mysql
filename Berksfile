#site :opscode
source "https://supermarket.chef.io"

metadata

cookbook 'collectd', github: 'rightscale-cookbooks-contrib/chef-collectd', branch: 'generalize_install_for_both_centos_and_ubuntu'
cookbook 'mysql', github: 'rightscale-cookbooks-contrib/mysql', branch: 'rs-fixes'
cookbook 'dns', github: 'rightscale-cookbooks-contrib/dns', branch: 'rightscale_development_v2'
cookbook 'database', github: 'rightscale-cookbooks-contrib/database', branch: 'rs-fixes'

cookbook 'rightscale_backup',github: 'rightscale-cookbooks/rightscale_backup', tag: 'v1.2.1'
cookbook 'rightscale_volume',github: 'rightscale-cookbooks/rightscale_volume', tag: 'v1.3.1'
cookbook 'rightscale_tag',github: 'rightscale-cookbooks/rightscale_tag', tag: 'v1.2.2'
cookbook 'machine_tag',github: 'rightscale-cookbooks/machine_tag', tag: 'v1.2.2'
cookbook 'ephemeral_lvm',github:'rightscale-cookbooks/ephemeral_lvm', tag:'v1.0.16'

group :integration do
  cookbook 'runit', '1.6.0'
  cookbook 'apt', '~> 2.9.2'
  cookbook 'yum-epel', '~> 0.4.0'
  cookbook 'curl', '~> 1.1.0'
  cookbook 'fake', path: './test/cookbooks/fake'
  cookbook 'rhsm', '~> 1.0.0'
end
