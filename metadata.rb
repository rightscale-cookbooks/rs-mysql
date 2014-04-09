name             'rs-mysql'
maintainer       'RightScale, Inc.'
maintainer_email 'cookbooks@rightscale.com'
license          'Apache 2.0'
description      'Installs and configures a MySQL server'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '1.0.0'

depends 'marker', '~> 1.0.0'
depends 'database', '~> 1.5.2'
depends 'mysql', '~> 4.0.18'
depends 'collectd', '~> 1.1.0'
depends 'rightscale_tag', '~> 1.0.1'
depends 'dns', '~> 1.0.3'

recipe 'rs-mysql::default', 'Sets up a standalone MySQL server'
recipe 'rs-mysql::collectd', 'Sets up collectd monitoring for MySQL server'
recipe 'rs-mysql::master', 'Sets up a MySQL master server'
recipe 'rs-mysql::slave', 'Sets up a MySQL slave server'

attribute 'rs-mysql/lineage',
  :display_name => 'MySQL Database Backup Lineage',
  :description => 'The prefix that will be used to name/locate the backup of the MySQL database server.',
  :required => 'required',
  :recipes => ['rs-mysql::default', 'rs-mysql::master', 'rs-mysql::slave']

attribute 'rs-mysql/server_usage',
  :display_name => 'Server Usage',
  :description => "The Server Usage method. It is either 'dedicated' or 'shared'. In a 'dedicated' server all" +
    " server resources are dedicated to MySQL. In a 'shared' server, MySQL utilizes only half of the resources." +
    " Example: 'dedicated'",
  :default => 'dedicated',
  :required => 'optional',
  :recipes => ['rs-mysql::default', 'rs-mysql::master', 'rs-mysql::slave']

attribute 'rs-mysql/server_root_password',
  :display_name => 'MySQL Root Password',
  :description => 'The root password for MySQL server. Example: cred:MYSQL_ROOT_PASSWORD',
  :required => 'required',
  :recipes => ['rs-mysql::default', 'rs-mysql::master', 'rs-mysql::slave']

attribute 'rs-mysql/application_username',
  :display_name => 'MySQL Application Username',
  :description => 'The username of the application user. Example: cred:MYSQL_APPLICATION_USERNAME',
  :required => 'optional',
  :recipes => ['rs-mysql::default', 'rs-mysql::master', 'rs-mysql::slave']

attribute 'rs-mysql/application_password',
  :display_name => 'MySQL Application Password',
  :description => 'The password of the application user. Example: cred:MYSQL_APPLICATION_PASSWORD',
  :required => 'optional',
  :recipes => ['rs-mysql::default', 'rs-mysql::master', 'rs-mysql::slave']

attribute 'rs-mysql/application_user_privileges',
  :display_name => 'MySQL Application User Privileges',
  :description => 'The privileges given to the application user. This can be an array of mysql privilege types.' +
    ' Example: select, update, insert',
  :required => 'optional',
  :type => 'array',
  :default => [:select, :update, :insert],
  :recipes => ['rs-mysql::default', 'rs-mysql::master', 'rs-mysql::slave']

attribute 'rs-mysql/application_database_name',
  :display_name => 'MySQL Database Name',
  :description => 'The name of the application database. Example: mydb',
  :required => 'optional',
  :recipes => ['rs-mysql::default', 'rs-mysql::master', 'rs-mysql::slave']

attribute 'rs-mysql/server_repl_password',
  :display_name => 'MySQL Slave Replication Password',
  :description => 'The replication password set on the master database and used by the slave to authenticate and' +
    ' connect. Example cred:MYSQL_REPLICATION_PASSWORD',
  :required => 'optional',
  :recipes => ['rs-mysql::default', 'rs-mysql::master', 'rs-mysql::slave']

attribute 'rs-mysql/master_fqdn',
  :display_name => 'MySQL Database FQDN',
  :description => 'The fully qualified domain name of the MySQL master database server.',
  :required => 'optional',
  :recipes => ['rs-mysql::master']

attribute 'rs-mysql/dns_user',
  :display_name => 'DNS User',
  :description => 'The user name to access and modify the DNS records.',
  :required => 'optional',
  :recipes => ['rs-mysql::master']

attribute 'rs-mysql/dns_password',
  :display_name => 'DNS Password',
  :description => 'The password to access and modify the DNS records.',
  :required => 'optional',
  :recipes => ['rs-mysql::master']
