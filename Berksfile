source 'https://supermarket.chef.io'

metadata

cookbook 'filesystem', github: 'rightscale-cookbooks-contrib/filesystem_cookbook', branch: 'update_lvm_cookbook_dependency_3'
cookbook 'marker', github: 'rightscale-cookbooks/marker', branch: 'chef-12-migration'
cookbook 'rightscale_backup', github: 'rightscale-cookbooks/rightscale_backup', branch: 'chef-12-migration'
cookbook 'rightscale_volume', github: 'rightscale-cookbooks/rightscale_volume', branch: 'chef-12-migration'
cookbook 'rightscale_tag', github: 'rightscale-cookbooks/rightscale_tag', branch: 'chef-12-migration'
cookbook 'machine_tag', github: 'rightscale-cookbooks/machine_tag', branch: 'chef-12-migration'
cookbook 'ephemeral_lvm', github: 'rightscale-cookbooks/ephemeral_lvm', branch: 'chef-12-migration'
cookbook 'rs-base', github: 'rightscale-cookbooks/rs-base', branch: 'chef-12-migration'
cookbook 'dns', github: 'rightscale-cookbooks-contrib/dns', branch: 'rightscale_development_v2'

group :integration do
  cookbook 'runit'
  cookbook 'apt'
  cookbook 'yum-epel'
  cookbook 'curl'
  cookbook 'fake', path: './test/cookbooks/fake'
  cookbook 'rhsm'
end
