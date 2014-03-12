name             'fake'
maintainer       'RightScale, Inc.'
maintainer_email 'cookbooks@rightscale.com'
license          'Apache 2.0'
description      'Installs/Configures a test mysql database server'
version          '0.1.0'

depends 'database'
depends 'rs-mysql'
depends 'rightscale_tag'

recipe 'fake::database_mysql', 'Prepares the test mysql database'
recipe 'fake::master', 'Sets up master db for the slave suite'
