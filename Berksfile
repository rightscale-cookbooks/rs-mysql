#site :opscode
source "https://supermarket.chef.io"

metadata

# kabam cookbooks
cookbook 'mysql', github: 'kabam/mysql', branch: 'rs-fixes', tag: 'v4.0.21'

# rightscale cookbooks
cookbook 'collectd', github: 'rightscale-cookbooks-contrib/chef-collectd', branch: 'generalize_install_for_both_centos_and_ubuntu'
cookbook 'dns', github: 'rightscale-cookbooks-contrib/dns', branch: 'rightscale_development_v2'
cookbook 'database', github: 'rightscale-cookbooks-contrib/database', branch: 'rs-fixes'

cookbook 'rightscale_backup',github: 'rightscale-cookbooks/rightscale_backup', branch: 'v1.2.0'
cookbook 'rightscale_volume',github: 'rightscale-cookbooks/rightscale_volume', branch: 'v1.3.0'
cookbook 'rightscale_tag',github: 'rightscale-cookbooks/rightscale_tag', branch: 'v1.1.0'
cookbook 'machine_tag',github: 'rightscale-cookbooks/machine_tag', branch: 'v1.1.0'
cookbook 'ephemeral_lvm',github:'rightscale-cookbooks/ephemeral_lvm', branch: 'v1.0.12'

group :integration do
  cookbook 'runit', '1.6.0'
  cookbook 'apt', '~> 2.9.2'
  cookbook 'yum-epel', '~> 0.4.0'
  cookbook 'curl', '~> 1.1.0'
  cookbook 'fake', path: './test/cookbooks/fake'
  cookbook 'rhsm', '~> 1.0.0'
end
