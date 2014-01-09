require 'spec_helper'

mysql_client_packages = []

case backend.check_os[:family]
when 'Ubuntu'
  mysql_client_packages = %w{ mysql-client libmysqlclient-dev }
when 'RedHat'
  mysql_client_packages = %w{ mysql mysql-devel }
end

describe 'MySQL client packages are installed' do
  mysql_client_packages.each do |pkg|
    describe package(pkg) do
      it { should be_installed }
    end
  end
end

# Verify mysql gem is installed to run mysql
describe package('mysql') do
  let(:path) { '/opt/chef/embedded/bin' }
  it { should be_installed.by('gem') }
end
