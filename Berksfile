source 'https://supermarket.chef.io'

metadata

# cookbook 'collectd', github: 'rightscale-cookbooks-contrib/chef-collectd', branch: 'generalize_install_for_both_centos_and_ubuntu'
# cookbook 'mysql', github: 'rightscale-cookbooks-contrib/mysql', branch: 'rs-fixes'
# cookbook 'dns', github: 'rightscale-cookbooks-contrib/dns', branch: 'rightscale_development_v2'
# cookbook 'database', github: 'rightscale-cookbooks-contrib/database', branch: 'rs-fixes'

cookbook 'marker', github: 'rightscale-cookbooks/marker', branch: 'chef-12-migration'
cookbook 'rightscale_backup', github: 'rightscale-cookbooks/rightscale_backup', branch: 'chef-12-migration'
cookbook 'rightscale_volume', github: 'rightscale-cookbooks/rightscale_volume', branch: 'chef-12-migration'
cookbook 'rightscale_tag', github: 'rightscale-cookbooks/rightscale_tag', branch: 'chef-12-migration'
cookbook 'machine_tag', github: 'rightscale-cookbooks/machine_tag', branch: 'chef-12-migration'
cookbook 'ephemeral_lvm', github: 'rightscale-cookbooks/ephemeral_lvm', tag: 'v1.0.16'

group :integration do
  cookbook 'runit'
  cookbook 'apt'
  cookbook 'yum-epel'
  cookbook 'curl'
  cookbook 'fake', path: './test/cookbooks/fake'
  cookbook 'rhsm'
end
