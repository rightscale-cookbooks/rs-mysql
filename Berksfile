site :opscode

metadata

cookbook 'collectd', github: 'EfrainOlivares/chef-collectd', branch: 'generalize_install_for_both_centos_and_ubuntu'
cookbook 'mysql', github: 'david-vo/mysql', branch: 'st_14_13_acu173881_add_rhel7_support'
cookbook 'dns', github: 'lopakadelp/dns', branch: 'rightscale_development_v2'
cookbook 'build-essential', '~> 1.4.4'
cookbook 'database', github: 'douglaswth-cookbooks/database', branch: 'rs-fixes'


group :integration do
  cookbook 'apt', '~> 2.3.0'
  cookbook 'yum', '~> 2.4.2'
  cookbook 'yum-epel', '~> 0.4.0'
  cookbook 'curl', '~> 1.1.0'
  cookbook 'fake', path: './test/cookbooks/fake'
  cookbook 'rhsm', '~> 1.0.0'
end
