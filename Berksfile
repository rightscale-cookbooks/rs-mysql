site :opscode

metadata

cookbook 'build-essential', '~> 1.4.4'
cookbook 'collectd', github: 'EfrainOlivares/chef-collectd', branch: 'generalize_install_for_both_centos_and_ubuntu'
cookbook 'mysql', github: 'arangamani-cookbooks/mysql', branch: 'COOK-2100'

group :integration do
  cookbook 'apt', '~> 2.3.0'
  cookbook 'yum', '~> 2.4.2'
  cookbook 'fake', path: './test/cookbooks/fake'
end
