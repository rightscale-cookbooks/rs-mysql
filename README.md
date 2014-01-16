# rs-mysql cookbook

[![Build Status](https://travis-ci.org/rightscale-cookbooks/rs-mysql.png?branch=master)](https://travis-ci.org/rightscale-cookbooks/rs-mysql)

Sets up a MySQL server and tunes the attributes used in `my.cnf` based on available system memory and the server usage
type.

Github Repository: [https://github.com/rightscale-cookbooks/rs-mysql](https://github.com/rightscale-cookbooks/rs-mysql)

# Requirements

* Requires Chef 11 or higher
* Platform
  * Ubuntu 12.04
  * CentOS 6
* Cookbooks
  * [marker](http://community.opscode.com/cookbooks/marker)
  * [mysql](http://community.opscode.com/cookbooks/mysql)
  * [collectd](http://community.opscode.com/cookbooks/collectd)

# Usage

To setup a MySQL server, place the `rs-mysql::server` recipe in the runlist.

# Attributes

* `node['rs-mysql']['server_usage']` - The server usage type. It should be either `'dedicated'` or `'shared'`. Default
  is `'dedicated'`.

# Recipes

## `rs-mysql::server`

Installs the MySQL server and tunes the attributes used in the `my.cnf` based on the available system memory and the
server usage type. If the server usage type is `'dedicated'`, all resources in the system are dedicated to the MySQL
server and if the usage type is `'shared'`, only half of the resources are used for the MySQL server. This `'shared'`
usage will be used in building a LAMP stack where the same system is used to run both the MySQL server and the PHP
application server. This recipe also installs the collectd plugins for MySQL.

# Author

Author:: RightScale, Inc. (<cookbooks@rightscale.com>)
