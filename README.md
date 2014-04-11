# rs-mysql cookbook

[![Build Status](https://travis-ci.org/rightscale-cookbooks/rs-mysql.png?branch=master)](https://travis-ci.org/rightscale-cookbooks/rs-mysql)

Sets up a MySQL server and tunes the attributes used in `my.cnf` based on available system memory and the server
usage type.

Github Repository: [https://github.com/rightscale-cookbooks/rs-mysql](https://github.com/rightscale-cookbooks/rs-mysql)

# Requirements

* Requires Chef 11 or higher
* Requires Ruby 1.9 of higher
* Platform
  * Ubuntu 12.04
  * CentOS 6
* Cookbooks
  * [marker](http://community.opscode.com/cookbooks/marker)
  * [mysql](http://community.opscode.com/cookbooks/mysql)
  * [collectd](http://community.opscode.com/cookbooks/collectd)
  * [database](http://community.opscode.com/cookbooks/database)
  * [rightscale_tag](http://community.opscode.com/cookbooks/rightscale_tag)

# Usage

To setup a standalone MySQL server, place the `rs-mysql::server` recipe in the runlist.

To setup a MySQL master-slave replication, place the `rs-mysql::master` recipe in the runlist for the master
server and the `rs-mysql::slave` recipe in the runlist for the slave server. The master server should be
operational before bringing up the slave server. Both the master and slave servers are tagged with required
information for replication. Please refer to the [rightscale_tag] cookbook for more information about the tags
added to database servers.

# Attributes

* `node['rs-mysql']['server_usage']` - The server usage type. It should be either `'dedicated'` or `'shared'`.
  Default is `'dedicated'`.
* `node['rs-mysql']['server_root_password']` - The root password for MySQL server.
* `node['rs-mysql']['server_repl_password']` - The replication password for MySQL server.
* `node['rs-mysql']['application_username']` - The database username to be created for the application.
* `node['rs-mysql']['application_password']` - The database password to be used for the application user.
* `node['rs-mysql']['application_user_privileges']` - The application user's privileges.
* `node['rs-mysql']['application_database_name']` - The name of the application database.
* `node['rs-mysql']['dns']['master_fqdn']` - The fully qualified domain name of the master database.
* `node['rs-mysql']['dns']['user_key']` - The user key for the DNS provider to access/modify DNS
records.
* `node['rs-mysql']['dns']['secret_key']`- The secret key for the DNS provider to access/modify DNS
records.

# Recipes

## `rs-mysql::server`

Installs the MySQL server and tunes the attributes used in the `my.cnf` based on the available system memory
and the server usage type. If the server usage type is `'dedicated'`, all resources in the system are dedicated
to the MySQL server and if the usage type is `'shared'`, only half of the resources are used for the MySQL server.
This `'shared'` usage will be used in building a LAMP stack where the same system is used to run both the MySQL
server and the PHP application server. This recipe also installs the collectd plugins for MySQL. It also tags
the server as a standalone MySQL server.

## `rs-mysql::master`

This recipe sets up the database to act as the master. It makes sure the database is not read only by overriding
the `mysql/tunable/read_only` to false and includes the `rs-mysql::server` recipe which installs MySQL and
performs the configuration. The master database specific tags are added to the server and the master is reset.
The master database can be provided with a fully qualified domain name (FQDN) by setting the
`node['rs-mysql']['dns']['master_fqdn']` attribute. The DNS provider credentials
(`node['rs-mysql']['dns']['user_key']` and `node['rs-mysql']['dns']['secret_key']`) must also be set
to create/update the DNS records in the DNS provider.

## `rs-mysql::slave`

This recipe modifies the MySQL server to be read only and includes the `rs-mysql::server` recipe which installs
MySQL, performs configuration, and tags the server as a slave server. It obtains the information about the master
database with the help of the [`find_database_servers`] helper method provided by
the [rightscale_tag] cookbook and changes the master host of the slave to the latest master
available in the deployment.

[rightscale_tag]: https://github.com/rightscale-cookbooks/rightscale_tag/blob/master/README.md
[`find_database_servers`]: https://github.com/rightscale-cookbooks/rightscale_tag#find_database_servers

# Author

Author:: RightScale, Inc. (<cookbooks@rightscale.com>)
