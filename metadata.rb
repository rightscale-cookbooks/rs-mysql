# frozen_string_literal: true
name             'rs-mysql'
maintainer       'RightScale, Inc.'
maintainer_email 'cookbooks@rightscale.com'
license          'Apache 2.0'
description      'Installs and configures a MySQL server'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '2.0.1'
issues_url       'https://github.com/rightscale-cookbooks/rs-mysql/issues' if respond_to?(:issues_url)
source_url       'https://github.com/rightscale-cookbooks/rs-mysql' if respond_to?(:source_url)
chef_version     '>= 12.0' if respond_to?(:chef_version)

depends 'chef_handler'
depends 'marker', '~> 2.0'
depends 'database'
depends 'mysql2_chef_gem'
depends 'mysql'
depends 'yum-mysql-community'
depends 'collectd'
depends 'rightscale_tag', '~> 2.0'
depends 'filesystem'
depends 'ephemeral_lvm', '~> 3.0'
depends 'rightscale_volume', '~> 2.0'
depends 'rightscale_backup', '~> 2.0'
depends 'build-essential'
depends 'rs-base', '~> 2.0'
depends 'dns'

recipe 'rs-mysql::default', 'Sets up a standalone MySQL server'
recipe 'rs-mysql::collectd', 'Sets up collectd monitoring for MySQL server'
recipe 'rs-mysql::master', 'Sets up a MySQL master server'
recipe 'rs-mysql::slave', 'Sets up a MySQL slave server'
recipe 'rs-mysql::volume', 'Creates a volume, attaches it to the server, and moves the MySQL data to the volume'
recipe 'rs-mysql::stripe', 'Creates volumes, attaches them to the server, sets up a striped LVM, and moves the MySQL' \
                           ' data to the volume'
recipe 'rs-mysql::backup', description: 'Creates a backup', thread: 'storage_backup'
recipe 'rs-mysql::decommission', 'Destroys LVM conditionally, detaches and destroys volumes. This recipe should' \
                                 ' be used as a decommission recipe in a RightScale ServerTemplate.'
recipe 'rs-mysql::schedule', 'Enable/disable periodic backups based on rs-mysql/schedule/enable'
recipe 'rs-mysql::slave_monitors', 'enables slave scripts'

attribute 'rs-mysql/server_usage',
  display_name: 'Server Usage',
  description: "The Server Usage method. It is either 'dedicated' or 'shared'. In a 'dedicated' server all" \
                  " server resources are dedicated to MySQL. In a 'shared' server, MySQL utilizes only half of the resources." \
                  " Example: 'dedicated'",
  default: 'dedicated',
  required: 'optional',
  recipes: ['rs-mysql::default', 'rs-mysql::master', 'rs-mysql::slave']

attribute 'rs-mysql/bind_network_interface',
  display_name: 'MySQL Bind Network Interface',
  description: 'The network interface to use for MySQL bind. It can be either' \
                  " 'private' or 'public' interface.",
  default: 'private',
  choice: %w(public private),
  required: 'optional',
  recipes: ['rs-mysql::default', 'rs-mysql::master', 'rs-mysql::slave']

attribute 'rs-mysql/server_root_password',
  display_name: 'MySQL Root Password',
  description: 'The root password for MySQL server. Example: cred:MYSQL_ROOT_PASSWORD',
  required: 'required',
  recipes: ['rs-mysql::default', 'rs-mysql::master', 'rs-mysql::slave']

attribute 'rs-mysql/application_username',
  display_name: 'MySQL Application Username',
  description: 'The username of the application user. Example: cred:MYSQL_APPLICATION_USERNAME',
  required: 'optional',
  recipes: ['rs-mysql::default', 'rs-mysql::master', 'rs-mysql::slave']

attribute 'rs-mysql/application_password',
  display_name: 'MySQL Application Password',
  description: 'The password of the application user. Example: cred:MYSQL_APPLICATION_PASSWORD',
  required: 'optional',
  recipes: ['rs-mysql::default', 'rs-mysql::master', 'rs-mysql::slave']

attribute 'rs-mysql/application_user_privileges',
  display_name: 'MySQL Application User Privileges',
  description: 'The privileges given to the application user. This can be an array of mysql privilege types.' \
                  ' Example: select, update, insert',
  required: 'optional',
  type: 'array',
  default: [:select, :update, :insert],
  recipes: ['rs-mysql::default', 'rs-mysql::master', 'rs-mysql::slave']

attribute 'rs-mysql/application_database_name',
  display_name: 'MySQL Database Name',
  description: 'The name of the application database. Example: mydb',
  required: 'optional',
  recipes: ['rs-mysql::default', 'rs-mysql::master', 'rs-mysql::slave']

attribute 'rs-mysql/server_repl_password',
  display_name: 'MySQL Slave Replication Password',
  description: 'The replication password set on the master database and used by the slave to authenticate and' \
                  ' connect. If not set, rs-mysql/server_root_password will be used. Example cred:MYSQL_REPLICATION_PASSWORD',
  required: 'optional',
  recipes: ['rs-mysql::default', 'rs-mysql::master', 'rs-mysql::slave']

attribute 'rs-mysql/device/count',
  display_name: 'Device Count',
  description: 'The number of devices to create and use in the Logical Volume. If this value is set to more than' \
                  ' 1, it will create the specified number of devices and create an LVM on the devices.',
  default: '2',
  recipes: ['rs-mysql::stripe', 'rs-mysql::decommission'],
  required: 'recommended'

attribute 'rs-mysql/device/mount_point',
  display_name: 'Device Mount Point',
  description: 'The mount point to mount the device on. Example: /mnt/storage',
  default: '/mnt/storage',
  recipes: ['rs-mysql::volume', 'rs-mysql::stripe', 'rs-mysql::decommission'],
  required: 'recommended'

attribute 'rs-mysql/device/nickname',
  display_name: 'Device Nickname',
  description: 'Nickname for the device. rs-mysql::volume uses this for the filesystem label, which is' \
                  ' restricted to 12 characters.  If longer than 12 characters, the filesystem label will be set to the' \
                  ' first 12 characters. Example: data_storage',
  default: 'data_storage',
  recipes: ['rs-mysql::volume', 'rs-mysql::stripe', 'rs-mysql::decommission'],
  required: 'recommended'

attribute 'rs-mysql/device/volume_size',
  display_name: 'Device Volume Size',
  description: 'Size of the volume or logical volume to create (in GB). Example: 10',
  default: '10',
  recipes: ['rs-mysql::volume', 'rs-mysql::stripe'],
  required: 'recommended'

attribute 'rs-mysql/device/iops',
  display_name: 'Device IOPS',
  description: 'IO Operations Per Second to use for the device. Currently this value is only used on AWS clouds.' \
                  ' Example: 100',
  recipes: ['rs-mysql::volume', 'rs-mysql::stripe'],
  required: 'optional'

attribute 'rs-mysql/device/volume_type',
  display_name: 'Volume Type',
  description: 'Volume Type to use for creating volumes. Example: gp2',
  recipes: ['rs-mysql::volume', 'rs-mysql::stripe'],
  required: 'optional'

attribute 'rs-mysql/device/filesystem',
  display_name: 'Device Filesystem',
  description: 'The filesystem to be used on the device. Defaults are based on OS and determined in' \
                  ' attributes/volume.rb. Example: ext4',
  recipes: ['rs-mysql::volume', 'rs-mysql::stripe'],
  required: 'optional'

attribute 'rs-mysql/device/detach_timeout',
  display_name: 'Detach Timeout',
  description: 'Amount of time (in seconds) to wait for a single volume to detach at decommission. Example: 300',
  default: '300',
  recipes: ['rs-mysql::volume', 'rs-mysql::stripe'],
  required: 'optional'

attribute 'rs-mysql/device/destroy_on_decommission',
  display_name: 'Destroy on Decommission',
  description: 'If set to true, the devices will be destroyed on decommission.',
  default: 'false',
  recipes: ['rs-mysql::decommission'],
  required: 'recommended'

attribute 'rs-mysql/backup/lineage',
  display_name: 'Backup Lineage',
  description: 'The prefix that will be used to name/locate the backup of the MySQL database server.',
  required: 'required',
  recipes: ['rs-mysql::default', 'rs-mysql::master', 'rs-mysql::slave', 'rs-mysql::backup']

attribute 'rs-mysql/restore/lineage',
  display_name: 'Restore Lineage',
  description: 'The lineage name to restore backups. Example: staging',
  recipes: ['rs-mysql::volume', 'rs-mysql::stripe'],
  required: 'recommended'

attribute 'rs-mysql/restore/timestamp',
  display_name: 'Restore Timestamp',
  description: 'The timestamp (in seconds since UNIX epoch) to select a backup to restore from.' \
                  ' The backup selected will have been created on or before this timestamp. Example: 1391473172',
  recipes: ['rs-mysql::volume', 'rs-mysql::stripe'],
  required: 'recommended'

attribute 'rs-mysql/backup/keep/dailies',
  display_name: 'Backup Keep Dailies',
  description: 'Number of daily backups to keep. Example: 14',
  default: '14',
  recipes: ['rs-mysql::backup'],
  required: 'optional'

attribute 'rs-mysql/backup/keep/weeklies',
  display_name: 'Backup Keep Weeklies',
  description: 'Number of weekly backups to keep. Example: 6',
  default: '6',
  recipes: ['rs-mysql::backup'],
  required: 'optional'

attribute 'rs-mysql/backup/keep/monthlies',
  display_name: 'Backup Keep Monthlies',
  description: 'Number of monthly backups to keep. Example: 12',
  default: '12',
  recipes: ['rs-mysql::backup'],
  required: 'optional'

attribute 'rs-mysql/backup/keep/yearlies',
  display_name: 'Backup Keep Yearlies',
  description: 'Number of yearly backups to keep. Example: 2',
  default: '2',
  recipes: ['rs-mysql::backup'],
  required: 'optional'

attribute 'rs-mysql/backup/keep/keep_last',
  display_name: 'Backup Keep Last Snapshots',
  description: 'Number of snapshots to keep. Example: 60',
  default: '60',
  recipes: ['rs-mysql::backup'],
  required: 'optional'

attribute 'rs-mysql/schedule/enable',
  display_name: 'Backup Schedule Enable',
  description: 'Enable or disable periodic backup schedule',
  default: 'false',
  choice: %w(true false),
  recipes: ['rs-mysql::schedule'],
  required: 'recommended'

attribute 'rs-mysql/schedule/hour',
  display_name: 'Backup Schedule Hour',
  description: "The hour to schedule the backup on. This value should abide by crontab syntax. Use '*' for taking" \
                  ' backups every hour. Example: 23',
  recipes: ['rs-mysql::schedule'],
  required: 'required'

attribute 'rs-mysql/schedule/minute',
  display_name: 'Backup Schedule Minute',
  description: 'The minute to schedule the backup on. This value should abide by crontab syntax. Example: 30',
  recipes: ['rs-mysql::schedule'],
  required: 'required'

attribute 'rs-mysql/dns/master_fqdn',
  display_name: 'MySQL Database FQDN',
  description: 'The fully qualified domain name of the MySQL master database server.',
  required: 'optional',
  recipes: ['rs-mysql::master']

attribute 'rs-mysql/dns/user_key',
  display_name: 'DNS User Key',
  description: 'The user key to access/modify the DNS records.',
  required: 'optional',
  recipes: ['rs-mysql::master']

attribute 'rs-mysql/dns/secret_key',
  display_name: 'DNS Secret Key',
  description: 'The secret key to access/modify the DNS records.',
  required: 'optional',
  recipes: ['rs-mysql::master']

attribute 'rs-mysql/import/private_key',
  display_name: 'Import Secret Key',
  description: 'The private key to access the repository via SSH. Example: Cred:DB_IMPORT_KEY',
  required: 'optional',
  recipes: ['rs-mysql::dump_import']

attribute 'rs-mysql/import/repository',
  display_name: 'Import Repository URL',
  description: 'The repository location containing the database dump file to import.' \
                  ' Example: git://example.com/dbfiles/database_dumpfiles.git',
  required: 'optional',
  recipes: ['rs-mysql::dump_import']

attribute 'rs-mysql/import/revision',
  display_name: 'Import Repository Revision',
  description: 'The revision of the database dump file to import.' \
                  ' Example: master',
  required: 'optional',
  recipes: ['rs-mysql::dump_import']

attribute 'rs-mysql/import/dump_file',
  display_name: 'Import Filename',
  description: 'Filename of the database dump file to import.' \
                  ' Example: dumpfile_20140102.gz',
  required: 'optional',
  recipes: ['rs-mysql::dump_import']

attribute 'rs-mysql/startup-timeout',
  display_name: 'MySQL Server Startup Timeout',
  description: 'MySQL Server Startup Timeout',
  required: 'optional',
  default: 300,
  recipes: ['rs-mysql::default']
