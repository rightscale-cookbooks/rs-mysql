# rs-mysql cookbook

[![Release](https://img.shields.io/github/release/rightscale-cookbooks/rs-mysql.svg?style=flat)][release]
[![Build Status](https://img.shields.io/travis/rightscale-cookbooks/rs-mysql.svg?style=flat)][travis]

[release]: https://github.com/rightscale-cookbooks/rs-mysql/releases/latest
[travis]: https://travis-ci.org/rightscale-cookbooks/rs-mysql

Provides recipes for managing a MySQL server with RightScale, including:

* Automatic tuning based on available system memory and server usage type
* High availability with master/slave replication including failover
* Database storage with cloud volumes including backup and restore

Github Repository: [https://github.com/rightscale-cookbooks/rs-mysql](https://github.com/rightscale-cookbooks/rs-mysql)

# Requirements

* Requires Chef 12
* Requires Ruby 2.3.1 of higher
* [RightLink 10](http://docs.rightscale.com/rl10/)
* See cookbook version 1.2.6 for chef11 support
* See cookbook version 1.1.9 for RightLink 6 support
* Platform
  * Ubuntu 12.04(MySQL 5.5, MySQL 5.6)
  * Ubuntu 14.04(MySQL 5.5, MySQL 5.6)
  * CentOS 6(MySQL 5.5, MySQL 5.6, MySQL 5.7)
  * CentOS 7(MySQL 5.5, MySQL 5.6, MySQL 5.7)
* Cookbooks
  * [marker](http://community.opscode.com/cookbooks/marker)
  * [mysql](http://community.opscode.com/cookbooks/mysql)
  * [collectd](https://github.com/rightscale-cookbooks-contrib/chef-collectd)
  * [database](https://github.com/rightscale-cookbooks-contrib/database)
  * [rightscale_tag](http://community.opscode.com/cookbooks/rightscale_tag)
  * [filesystem](http://community.opscode.com/cookbooks/filesystem)
  * [lvm](http://community.opscode.com/cookbooks/lvm)
  * [rightscale_volume](http://community.opscode.com/cookbooks/rightscale_volume)
  * [rightscale_backup](http://community.opscode.com/cookbooks/rightscale_backup)
  * [chef_handler](http://community.opscode.com/cookbooks/chef_handler)
  * [dns](https://github.com/rightscale-cookbooks-contrib/dns)

See the `Berksfile` and `metadata.rb` for up to date dependency information.

# Usage

To setup a standalone MySQL server, place the `rs-mysql::default` recipe in the runlist.

## Creating a new volume

To create a new volume and move the MySQL database to it, run the `rs-mysql::volume` recipe with the following
attributes set:

- `node['rs-mysql']['device']['nickname']` - the nickname of the volume
- `node['rs-mysql']['device']['volume_size']` - the size of the volume to create
- `node['rs-mysql']['device']['filesystem']` - the filesystem to use on the volume
- `node['rs-mysql']['device']['mount_point']` - the location to mount the volume

This will create a new volume, attach it to the server, format it with the filesystem specified, mount it on the
location specified, and move the MySQL database to it.

### Provisioned IOPS on EC2

To create a volume with IOPS on EC2, set the following attribute before running the `rs-mysql::volume` recipe:

- `node['rs-mysql']['device']['iops']` - the value of IOPS to use

## Creating a logical volume with striping

To create a logical volume with striping using LVM and move the MySQL database to it, run the `rs-mysql::stripe` recipe
with the following attributes set:

- `node['rs-mysql']['device']['nickname']` - the nickname to use as prefix for the logical volume
- `node['rs-mysql']['device']['count']` - number of volumes to create in the logical volume
- `node['rs-mysql']['device']['volume_size']` - the total size of the logical volume
- `node['rs-mysql']['device']['filesystem']` - the filesystem to use on the logical volume
- `node['rs-mysql']['device']['mount_point']` - the location to mount the logical volume

This will create the number of volumes specified in `node['rs-mysql']['device']['count']`. Each volume created will have
a nickname of `"#{nickname}_#{device_number}"`. The size for each volume is calculated by the following formula:

```ruby
(total_size.to_f / device_count.to_f).ceil

# For example, total size = 10, stripe count = 3
(10.0 / 3.0).ceil
# => 4.0
```

This will create a volume group with the name `"#{nickname}-vg"` and a logical volume in it with the name
`"#{nickname}-lv"`, format it with the filesystem specified, mount it on the location specified, and move the MySQL
database to it.

## Master/Slave replication and Failover

To setup a MySQL master/slave replication, place the `rs-mysql::master` recipe in the runlist for the master
server and the `rs-mysql::slave` recipe in the runlist for the slave server. The master server should be
operational before bringing up the slave server. Both the master and slave servers are tagged with required
information for replication. Please refer to the [rightscale_tag] cookbook for more information about the tags
added to database servers. When using volumes with master/slave replication, the `rs-mysql::volume` or
`rs-mysql::stripe` recipe should run before the `rs-mysql::master` or `rs-mysql::slave` recipe.

To promote a slave to master in a failover situation just run the `rs-mysql::master` recipe on the slave that needs to
be promoted. If there are other slaves in the deployment, the `rs-mysql::slave` recipe should be re-run on those servers
as well. If the old master is still working, it can be demoted to a slave by running the `rs-mysql::slave` recipe as
well.

## Backing up volume(s) & Cleaning up backups

To create a backup of all volumes attached to the server, run the `rs-mysql::backup` recipe with the following
attributes set:

- `node['rs-mysql']['backup']['lineage']` - the lineage to be used for the backup

The backup process will create a snapshot of all volumes attached to the server (except the boot disk if there is one).
During the backup process, the MySQL database will be read-only for a period to ensure a consistent backup, so it is
recommended that it only runs on a slave MySQL database server. The backup recipe also handles the cleanup of old
volume snapshots and accepts the following attributes:

- `node['rs-mysql']['backup']['keep']['keep_last']` - number of last backups to keep from deleting
- `node['rs-mysql']['backup']['keep']['dailies']` - number of daily backups to keep
- `node['rs-mysql']['backup']['keep']['weeklies']` - number of weekly backups to keep
- `node['rs-mysql']['backup']['keep']['monthlies']` - number of monthly backups to keep
- `node['rs-mysql']['backup']['keep']['yearlies']` - number of yearly backups to keep

This will cleanup the old snapshots on the cloud based on the criteria specified.

## Restoring a volume from a backup

To restore a volume from backup, run the `rs-mysql::volume` recipe with the same set of attributes mentioned in the
[previous section](#creating-a-new-volume) along with the following attribute:

- `node['rs-mysql']['restore']['lineage']` - the lineage to restore the backup from

This will restore the volume from the backup instead of creating a new one. By default, the backup with the latest
timestamp will be restored. To restore backup from a specific timestamp, set the following attribute:

- `node['rs-mysql']['restore']['timestamp']` - the timestamp of the backup to restore from (in seconds since UNIX epoch)

## Restoring a logical volume composed of multiple volumes from a backup

To restore a logical volume composed of multiple volumes from a backup, run the `rs-mysql::stripe` recipe with the
same set of attributes mentioned in the [previous section](#creating-stripe-of-volumes) along with the following
attribute:

- `node['rs-mysql']['restore']['lineage']` - the lineage to restore the backup from

This will restore multiple volumes from the backup matching the lineage. By default, the backup with the latest
timestamp will be restored. To restore a backup from a specific timestamp, set the following attribute:

- `node['rs-mysql']['restore']['timestamp']` - the timestamp of the backup to restore from (in seconds since UNIX epoch)

## Scheduling automated backups of volume(s)

To schedule automated backups, run the `rs-mysql::schedule` recipe with the following attributes set:

- `node['rs-mysql']['schedule']['enable']` - to enable/disable automated backups
- `node['rs-mysql']['schedule']['hour']` - the hour to take the backup on (should use crontab syntax)
- `node['rs-mysql']['schedule']['minute']` - the minute to take the backup on (should use crontab syntax)
- `node['rs-mysql']['backup']['lineage']` - the lineage name to be used for the backup

This will create a crontab entry to run the `rs-mysql::backup` recipe periodically at the given minute and hour. To
disable the automated backups, simply set `node['rs-mysql']['schedule']['enable']` to `false` and rerun the
`rs-mysql::schedule` recipe and this will remove the crontab entry.

## Deleting volume(s)

This operation should be part of the decommission bundle in a RightScale ServerTemplate where the volumes attached to
the server are detached and deleted from the cloud but this can also be used as an operational recipe. This recipe will
do nothing in the following conditions:

- when the server enters a stop state
- when the server reboots

This recipe also has a safety attribute `node['rs-mysql']['device']['destroy_on_decommission']`. This attribute will be
set to `false` by default and should be overridden and set to `true` in order for the devices to be detached and
deleted. If an LVM is found (created using `rs-mysql::stripe`), the LVM will be conditionally removed before detaching
the volume.

# Attributes

- `node['rs-mysql']['server_usage']` - The server usage type. It should be either `'dedicated'` or `'shared'`.
  Default is `'dedicated'`.
- `node['rs-mysql']['server_root_password']` - The root password for MySQL server.
- `node['rs-mysql']['server_repl_password']` - The replication password for MySQL server.
- `node['rs-mysql']['application_username']` - The database username to be created for the application.
- `node['rs-mysql']['application_password']` - The database password to be used for the application user.
- `node['rs-mysql']['application_user_privileges']` - The application user's privileges.
- `node['rs-mysql']['application_database_name']` - The name of the application database.
- `node['rs-mysql']['import']['repository']` - Repository location containing the database dump file to import.
- `node['rs-mysql']['import']['private_key']` - The private key to access the repository via SSH.
- `node['rs-mysql']['import']['revision']` - The revision of the database dump file to import.
- `node['rs-mysql']['import']['dump_file']` - Filename of the database dump file to import.
- `node['rs-mysql']['dns']['master_fqdn']` - The fully qualified domain name of the master database.
- `node['rs-mysql']['dns']['user_key']` - The user key for the DNS provider to access/modify DNS
records.
- `node['rs-mysql']['dns']['secret_key']`- The secret key for the DNS provider to access/modify DNS
records.
- `node['rs-mysql']['device']['nickname']` - The nickname of the device or the logical volume comprising multiple
  devices. Default is `'data_storage'`.
- `node['rs-mysql']['device']['mount_point']` - The mount point for the device. Default is `'/mnt/storage'`.
- `node['rs-mysql']['device']['volume_size']` - The size (in gigabytes) of the volume to be created. If multiple
  devices are used, this will be the total size of the logical volume. Default is `10`.
- `node['rs-mysql']['device']['count']` - The number of devices to be created for the logical volume. Default is `2`.
- `node['rs-mysql']['device']['iops']` - The IOPS value to be used for EC2 Provisioned IOPS. This attribute should only
  be used with Amazon EC2. Default is `nil`.
- `node['rs-mysql']['device']['filesystem']` - The filesystem to be used on the device. Default is `'ext4'`.
- `node['rs-mysql']['device']['detach_timeout']` - Amount of time (in seconds) to wait for a volume to detach at
  decommission. Default is `300` (5 minutes).
- `node['rs-mysql']['device']['destroy_on_decommission']` - Whether to destroy the device during the decommission of the
  server. Default is `false`.
- `node['rs-mysql']['device']['mkfs_options']` - Additional mkfs options for formatting the device. Default is `'-F'`
  which is required to avoid warnings about formatting the whole device.
- `node['rs-mysql']['device']['stripe_size']` - The stripe size to use on LVM. Default is `512`.
- `node['rs-mysql']['backup']['lineage']` - The backup lineage. Default is `nil`.
- `node['rs-mysql']['backup']['keep']['keep_last']` - Maximum snapshots to keep. Default is `60`.
- `node['rs-mysql']['backup']['keep']['dailies']` - Number of daily backups to keep. Default is `14`.
- `node['rs-mysql']['backup']['keep']['weeklies']` - Number of weekly backups to keep. Default is `6`.
- `node['rs-mysql']['backup']['keep']['monthlies']` - Number of monthly backups to keep. Default is `12`.
- `node['rs-mysql']['backup']['keep']['yearlies']` - Number of yearly backups to keep. Default is `2`.
- `node['rs-mysql']['restore']['lineage']` - The name of the lineage to restore the backups from. Default is `nil`.
- `node['rs-mysql']['restore']['timestamp']` - The timestamp to restore backup taken on or before the timestamp in the
  same lineage. Default is `nil`.
- `node['rs-mysql']['schedule']['enable']` - Enable/disable automated backups. Default is `false`.
- `node['rs-mysql']['schedule']['hour']` - The backup schedule hour. Default is `nil`.
- `node['rs-mysql']['schedule']['minute']` - The backup schedule minute. Default is `nil`.
- `node['rightscale']['decom_reason']` - Set from RL10 Shutdown Reason Rightscript to determine how to handle
   rs-mysql::decommission behavior

# Recipes

## `rs-mysql::default`

Installs the MySQL server and tunes the attributes used in the `my.cnf` based on the available system memory
and the server usage type. If the server usage type is `'dedicated'`, all resources in the system are dedicated
to the MySQL server and if the usage type is `'shared'`, only half of the resources are used for the MySQL server.
This `'shared'` usage will be used in building a LAMP stack where the same system is used to run both the MySQL
server and the PHP application server. This recipe also tags the server as a standalone MySQL server.

## `rs-mysql::volume`

Creates a new volume from scratch or from an existing backup based on the value provided in the
`node['rs-mysql']['restore']['lineage']` attribute. If this attribute is set, the volume will be restored from a
backup matching this lineage otherwise a new volume will be created from scratch. This recipe will also format the
volume using the filesystem specified in `node['rs-mysql']['device']['filesystem']`, mount the volume on the location
specified in `node['rs-mysql']['device']['mount_point']`, and move the MySQL database directory to the volume.

## `rs-mysql::stripe`

Creates a new logical volume composed of volumes from scratch or from an existing backup based on the
value provided in the `node['rs-mysql']['restore']['lineage']` attribute. If this attribute is set, the volumes will be
restored from a backup matching this lineage otherwise a new logical volume composed of volumes will be created from
scratch. This recipe will create a striped logical volume using LVM on the volumes and format the logical volume
using the filesystem specified in `node['rs-mysql']['device']['filesystem']`. This will also mount the volume on the
location specified in `node['rs-mysql']['device']['mount_point']` and move the MySQL database directory to the logical
volume.

## `rs-mysql::master`

This recipe sets up the database to act as the master. It makes sure the database is not read only by overriding
the `mysql/tunable/read_only` to false and includes the `rs-mysql::default` recipe which installs MySQL and
performs the configuration. The master database specific tags are added to the server and the master is reset.
The master database can be provided with a fully qualified domain name (FQDN) by setting the
`node['rs-mysql']['dns']['master_fqdn']` attribute. The DNS provider credentials
(`node['rs-mysql']['dns']['user_key']` and `node['rs-mysql']['dns']['secret_key']`) must also be set
to create/update the DNS records in the DNS provider.

## `rs-mysql::slave`

This recipe modifies the MySQL server to be read only and includes the `rs-mysql::default` recipe which installs
MySQL, performs configuration, and tags the server as a slave server. It obtains the information about the master
database with the help of the [`find_database_servers`] helper method provided by the [rightscale_tag] cookbook and
changes the master host of the slave to the latest master available in the deployment. If this recipe is run after
`rs-mysql::volume` or `rs-mysql::stripe` and a backup was restored, this recipe will use information from the backup to
assist with catching up with the master MySQL database.

## `rs-mysql::backup`

Takes a backup of all volumes attached to the server (except boot disks if there are any) with the lineage specified
in the `node['rs-mysql']['backup']['lineage']` attribute. During the backup process, the MySQL database will be
read-only and the filesystem will be frozen. The filesystem will be unfrozen and the MySQL database will no longer be
read-only after the backup even if the backup process fails with the help of a chef exception handler. This recipe will
also clean up the volume snapshots based on the criteria specified in the `rs-mysql/backup/keep/*` attributes.

## `rs-mysql::schedule`

Adds or removes the crontab entry for taking backups periodically at the minute and hour provided via
`node['rs-mysql']['schedule']['minute']` and `node['rs-mysql']['schedule']['hour']` attributes. The recipe uses the
`node['rs-mysql']['schedule']['enable']` attribute to determine whether to add or remove the crontab entry.

## `rs-mysql::decommission`

If the `node['rs-mysql']['device']['destroy_on_decommission']` attribute is set to true, this recipe moves the MySQL
database back to the root volume, drops the database specified by `node['rs-mysql']['application_database_name']` if it
is specified, and detaches and deletes the volumes attached to the server. This operation will be skipped if the server
is entering the stop state or rebooting.

## `rs-mysql::dump_import`

Retrieves a dump file from a Git repository and imports it to the database server. The Git repository is
specified by `node['rs-mysql']['import']['repository']` with revision/branch specified by
`node['rs-mysql']['import']['revision']`. The dump file in the repository is specified by
`node['rs-mysql']['import']['dump_file']`. The private key attribute, `node['rs-mysql']['import']['private_key']`,
must be set if retrieving from a private repository.

## `rs-mysql::collectd`

Installs the collectd plugins for MySQL.

[rightscale_tag]: https://github.com/rightscale-cookbooks/rightscale_tag/blob/master/README.md
[`find_database_servers`]: https://github.com/rightscale-cookbooks/rightscale_tag#find_database_servers

# Author

Author:: RightScale, Inc. (<cookbooks@rightscale.com>)
