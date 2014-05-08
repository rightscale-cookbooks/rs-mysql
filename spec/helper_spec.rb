require_relative 'spec_helper'
require 'helper'
require 'mysql'

describe RsMysql::Helper do
  let(:mysql_connection_info) do
    {
      host: 'localhost',
      username: 'root',
      password: 'rootpass',
    }
  end

  context 'with a MySQL server that is not a master or slave' do
    before do
      connection = double
      master_status = double
      slave_status = double
      Mysql.stub(:new).with('localhost', 'root', 'rootpass').and_return(connection)
      allow(connection).to receive(:query).with('SHOW MASTER STATUS').and_return(master_status)
      allow(connection).to receive(:query).with('SHOW SLAVE STATUS').and_return(slave_status)
      allow(connection).to receive(:close)
      allow(master_status).to receive(:fetch_hash).and_return(nil)
      allow(slave_status).to receive(:fetch_hash).and_return(nil)
    end

    it 'does not get any MySQL master info' do
      expect(described_class.get_master_info(mysql_connection_info)).to eq({})
    end
  end

  context 'with a MySQL master' do
    before do
      connection = double
      master_status = double
      slave_status = double
      Mysql.stub(:new).with('localhost', 'root', 'rootpass').and_return(connection)
      allow(connection).to receive(:query).with('SHOW MASTER STATUS').and_return(master_status)
      allow(connection).to receive(:query).with('SHOW SLAVE STATUS').and_return(slave_status)
      allow(connection).to receive(:close)
      allow(master_status).to receive(:fetch_hash).and_return({
        'File' => 'mysql-bin.000012',
        'Position' => '394',
        'Binlog_Do_DB' => '',
        'Binlog_Ignore' => '',
      })
      allow(slave_status).to receive(:fetch_hash).and_return(nil)
    end

    it 'gets the MySQL master info' do
      expect(described_class.get_master_info(mysql_connection_info)).to eq({
        file: 'mysql-bin.000012',
        position: '394',
      })
    end
  end

  context 'with a MySQL slave' do
    before do
      connection = double
      master_status = double
      slave_status = double
      Mysql.stub(:new).with('localhost', 'root', 'rootpass').and_return(connection)
      allow(connection).to receive(:query).with('SHOW MASTER STATUS').and_return(master_status)
      allow(connection).to receive(:query).with('SHOW SLAVE STATUS').and_return(slave_status)
      allow(connection).to receive(:close)
      allow(master_status).to receive(:fetch_hash).and_return({
        'File' => 'mysql-bin.000001',
        'Position' => '107',
        'Binlog_Do_DB' => '',
        'Binlog_Ignore_DB' => '',
      })
      allow(slave_status).to receive(:fetch_hash).and_return({
        'Slave_IO_State' => 'Waiting for master to send event',
        'Master_Host' => '10.240.180.148',
        'Master_User' => 'repl',
        'Master_Port' => '3306',
        'Connect_Retry' => '60',
        'Master_Log_File' => 'mysql-bin.000001',
        'Read_Master_Log_Pos' => '107',
        'Relay_Log_File' => 'mysqld-relay-bin.000002',
        'Relay_Log_Pos' => '253',
        'Relay_Master_Log_File' => 'mysql-bin.000012',
        'Slave_IO_Running' => 'Yes',
        'Slave_SQL_Running' => 'Yes',
        'Replicate_Do_DB' => '',
        'Replicate_Ignore_DB' => '',
        'Replicate_Do_Table' => '',
        'Replicate_Ignore_Table' => '',
        'Replicate_Wild_Do_Table' => '',
        'Replicate_Wild_Ignore_Table' => '',
        'Last_Errno' => '0',
        'Last_Error' => '',
        'Skip_Counter' => '0',
        'Exec_Master_Log_Pos' => '394',
        'Relay_Log_Space' => '410',
        'Until_Condition' => 'None',
        'Until_Log_File' => '',
        'Until_Log_Pos' => '0',
        'Master_SSL_Allowed' => 'No',
        'Master_SSL_CA_File' => '',
        'Master_SSL_CA_Path' => '',
        'Master_SSL_Cert' => '',
        'Master_SSL_Cipher' => '',
        'Master_SSL_Key' => '',
        'Seconds_Behind_Master' => '0',
        'Master_SSL_Verify_Server_Cert' => 'No',
        'Last_IO_Errno' => '0',
        'Last_IO_Error' => '',
        'Last_SQL_Errno' => '0',
        'Last_SQL_Error' => '',
        'Replicate_Ignore_Server_Ids' => '',
        'Master_Server_Id' => '1806882264',
      })
    end

    it 'gets the MySQL master info' do
      expect(described_class.get_master_info(mysql_connection_info)).to eq({
        file: 'mysql-bin.000012',
        position: '394',
      })
    end
  end
end
