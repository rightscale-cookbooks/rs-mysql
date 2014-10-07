# Slave

require 'spec_helper'

describe "Verify parameters directly from msyql" do
  {
    log_bin: 1,
    read_only: 1,
    binlog_format: "MIXED",
    expire_logs_days: 10
  }.each do |attribute, value|
    it "parameter #{attribute} should return #{value}" do
      db.query("SELECT @@global.#{attribute}").entries.first["@@global.#{attribute}"].should == value
    end
  end
end

describe "Verify replication setup" do
 it "should have 'repl' user created" do
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

describe "Check slave status" do
  describe "Master_Host matches 10.10.3.2" do
    describe command(
      "echo \"SHOW SLAVE STATUS \\G \" | mysql --user=root --password=rootpass"
    ) do
      its(:stdout) { should match /Master_Host: 10\.10\.3\.2/ }
    end
  end

  describe "Master_Port matches 3306" do
    describe command(
      "echo \"SHOW SLAVE STATUS \\G \" | mysql --user=root --password=rootpass"
    ) do
      its(:stdout) { should match /Master_Port: 3306/ }
    end
  end

end

# Verify tags
describe "Slave database tags" do
  let(:host_name) { Socket.gethostname.split('.').first }
  let(:slave_tags) do
    MachineTag::Set.new(
      JSON.parse(IO.read("/vagrant/cache_dir/machine_tag_cache/#{host_name}/tags.json"))
    )
  end

  it "should have a UUID of 2222222" do
    slave_tags['server:uuid'].first.value.should eq('2222222')
  end

  it "should have a public of 10.10.2.2" do
    slave_tags['server:public_ip_0'].first.value.should eq('10.10.2.2')
  end

  it "should have a private ip address of 10.0.2.15" do
    slave_tags['server:private_ip_0'].first.value.should eq('10.0.2.15')
  end

  it "should have a bind port of 3306" do
    slave_tags['database:bind_port'].first.value.should eq('3306')
  end

  it "should have 5 database specific entries" do
    slave_tags['database'].length.should eq(5)
  end

  it "should be active" do
    slave_tags['database:active'].first.value.should be_truthy
  end

  it "should have a lineage of lineage" do
    slave_tags['database:lineage'].first.value.should eq('lineage')
  end

  # We want to test that the slave_active timestamp is a reasonable value; arbitrarily within the last 24 hours
  let(:db_time) { Time.at(slave_tags['database:slave_active'].first.value.to_i) }

  it "should have a slave_active value that is valid (within the last 24 hours)" do
    (Time.now - db_time).should < 86400
  end
end
