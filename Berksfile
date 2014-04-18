site :opscode

metadata

cookbook 'filesystem', github: 'douglaswth-cookbooks/filesystem_cookbook', branch: 'fsfreeze'
cookbook 'collectd', github: 'EfrainOlivares/chef-collectd', branch: 'generalize_install_for_both_centos_and_ubuntu'
cookbook 'mysql', github: 'arangamani-cookbooks/mysql', branch: 'rs-fixes'
cookbook 'dns', github: 'lopakadelp/dns', branch: 'rightscale_development_v2'
cookbook 'build-essential', '~> 1.4.4'

group :integration do
  cookbook 'apt', '~> 2.3.0'
  cookbook 'yum', '~> 2.4.2'
  cookbook 'fake', path: './test/cookbooks/fake'
end
