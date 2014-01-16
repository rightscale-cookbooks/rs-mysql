name             'rs-mysql'
maintainer       'RightScale, Inc.'
maintainer_email 'cookbooks@rightscale.com'
license          'Apache 2.0'
description      'Installs and configures a MySQL server'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

depends 'marker', '~> 1.0.0'
depends 'database', '~> 1.5.2'
depends 'mysql', '~> 4.0.18'
depends 'collectd', '~> 1.1.0'

recipe 'rs-mysql::server', 'Sets up a MySQL server'

attribute 'rs-mysql/server_usage',
  :display_name => 'Server Usage',
  :description => "The Server Usage method. It is either 'dedicated' or 'shared'. In a 'dedicated' server all" +
    " server resources are dedicated to MySQL. In a 'shared' server, MySQL utilizes only half of the resources." +
    " Example: 'dedicated'",
  :default => 'dedicated',
  :required => 'optional',
  :recipes => ['rs-mysql::server']

attribute 'rs-mysql/server_root_password',
  :display_name => 'MySQL Root Password',
  :description => 'The root password for MySQL server. Example: cred:MYSQL_ROOT_PASSWORD',
  :required => 'required',
  :recipes => ['rs-mysql::server']

attribute 'rs-mysql/application_username',
  :display_name => 'MySQL Application Username',
  :description => 'The username of the application user. Example: cred:MYSQL_APPLICATION_USERNAME',
  :required => 'optional',
  :recipes => ['rs-mysql::server']

attribute 'rs-mysql/application_password',
  :display_name => 'MySQL Application Password',
  :description => 'The password of the application user. Example: cred:MYSQL_APPLICATION_PASSWORD',
  :required => 'optional',
  :recipes => ['rs-mysql::server']

attribute 'rs-mysql/application_user_privileges',
  :display_name => 'MySQL Application User Privileges',
  :description => 'The privileges given to the application user. This can be an array of mysql privilege types.' +
    ' Example: select, update, insert',
  :required => 'optional',
  :type => 'array',
  :default => [:select, :update, :insert],
  :recipes => ['rs-mysql::server']

attribute 'rs-mysql/application_database_name',
  :display_name => 'MySQL Database Name',
  :description => 'The name of the database. Example: mydb',
  :required => 'optional',
  :recipes => ['rs-mysql::server']
