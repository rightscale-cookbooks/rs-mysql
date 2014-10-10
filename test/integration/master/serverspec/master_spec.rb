# Master

require 'spec_helper'
require 'socket'

describe "Verify parameters directly from msyql" do
  {
    log_bin: 1,
    read_only: 0,
    binlog_format: "MIXED",
    expire_logs_days: 10
  }.each do |attribute, value|
    it "parameter #{attribute} should return #{value}" do
      db.query("SELECT @@global.#{attribute}").entries.first["@@global.#{attribute}"].should  == value
    end
  end
end

describe "Verify replication setup" do
 it "should have 'repl' created" do
   db.query("SELECT DISTINCT user FROM mysql.user").entries.count { |u| u['user'] == 'repl' }.should == 1
 end

 it "repl user should have replication privileges" do
   db.query("SHOW GRANTS FOR 'repl'").entries.first['Grants for repl@%'].should =~ /^GRANT REPLICATION SLAVE ON \*\.\* TO \'repl\'/
 end
end

describe "Verify master status" do
  let(:query_entries) { db.query('SHOW MASTER STATUS').entries }

  it "should have entry for mysql-bin file" do
   query_entries[0]['File'].should =~ /^mysql-bin/
  end

  it "should have non-zero position marker" do
   query_entries[0]['Position'].should_not == 0
  end
end

# The kitchen.yml file is set up to provide a public ip in the master suite. This is what this is testing.
# The slave setup will provide a null public, and a private ip.
describe "Verify valid server-id entry" do
  it "should correspond to the result of IPAddr converting 10.10.1.1 to an integer" do
    db.query("SHOW VARIABLES LIKE 'server_id'").entries.first['Value'].to_i.should == 168427777
  end
end

# Verify tags
describe "Master database tags" do
  let(:host_name) { Socket.gethostname.split('.').first }
  let(:master_tags) do
    MachineTag::Set.new(
      JSON.parse(IO.read("/vagrant/cache_dir/machine_tag_cache/#{host_name}/tags.json"))
    )
  end

  it "should have a UUID of 1111111" do
    master_tags['server:uuid'].first.value.should eq('1111111')
  end

  it "should have a public IP of 10.10.1.1" do
    master_tags['server:public_ip_0'].first.value.should eq('10.10.1.1')
  end

  it "should have a bind ip address of 10.0.2.15" do
    master_tags['database:bind_ip_address'].first.value.should eq('10.0.2.15')
  end

  it "should have a bind port of 3306" do
    master_tags['database:bind_port'].first.value.should eq('3306')
  end

  it "should have 5 database specific entries" do
    master_tags['database'].length.should eq(5)
  end

  it "should be active" do
    master_tags['database:active'].first.value.should be_truthy
  end

  it "should have a lineage of lineage" do
    master_tags['database:lineage'].first.value.should eq('lineage')
  end

  # We want to test that the master_active timestamp is a reasonable value; arbitrarily within the last 24 hours
  let(:db_time) { Time.at(master_tags['database:master_active'].first.value.to_i) }

  it "should have a master_active value that is valid (within the last 24 hours)" do
    (Time.now - db_time).should < 86400
  end
end
