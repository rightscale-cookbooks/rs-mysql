# dump_import_plain

require 'spec_helper'
require 'socket'

describe "Verify database 'app_test' imported" do
 it "should have database 'app_test' created" do
   db.query("SHOW DATABASES LIKE 'app_test'").entries.first['Database (app_test)'].should == 'app_test'
 end
end

describe "Verify 'app_test.app_test' table exists with imported content" do
 it "should have 3 rows of content in table 'app_test.app_test' created" do
   db.query("SELECT * FROM app_test.app_test WHERE id=1").entries.first['name'].should == 'app_test1'
   db.query("SELECT * FROM app_test.app_test WHERE id=2").entries.first['name'].should == 'app_test2'
   db.query("SELECT * FROM app_test.app_test WHERE id=3").entries.first['name'].should == 'app_test3'
 end
end
