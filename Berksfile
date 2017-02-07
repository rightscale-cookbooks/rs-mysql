# frozen_string_literal: true
source 'https://supermarket.chef.io'

metadata

cookbook 'filesystem', github: 'rightscale-cookbooks-contrib/filesystem_cookbook', branch: 'update_lvm_cookbook_dependency_3'
cookbook 'marker', github: 'rightscale-cookbooks/marker'
cookbook 'rightscale_backup', github: 'rightscale-cookbooks/rightscale_backup'
cookbook 'rightscale_volume', github: 'rightscale-cookbooks/rightscale_volume'
cookbook 'rightscale_tag', github: 'rightscale-cookbooks/rightscale_tag'
cookbook 'machine_tag', github: 'rightscale-cookbooks/machine_tag'
cookbook 'rs-base', github: 'rightscale-cookbooks/rs-base'
cookbook 'dns', github: 'rightscale-cookbooks-contrib/dns', branch: 'rightscale_development_v2'

group :integration do
  cookbook 'runit'
  cookbook 'apt'
  cookbook 'yum-epel'
  cookbook 'curl'
  cookbook 'fake', path: './test/cookbooks/fake'
  cookbook 'rhsm'
end
