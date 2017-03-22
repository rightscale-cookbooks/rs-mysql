# frozen_string_literal: true
source 'https://supermarket.chef.io'

metadata

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
