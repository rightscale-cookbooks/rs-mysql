rs-mysql Cookbook CHANGELOG
=======================

This file is used to list changes made in each version of the rs-mysql cookbook.

v1.2.3
------

- Updates collectd monitors to work with collectd v5

v1.2.2
------

- Run pvscan after volumes attached for stripe.  Behavior seen in CentOS 6.6 where volumes attached are not
  immediately seen as part of a Logical Volume.

v1.2.1
------

- Hard Setting versions in metadata and berksfile
- Locking down aws, ohai, and build-essential so it doesn't pull in chef12 libs

v1.2.0
------
- add support for RightLink 10

v1.1.9
------

- No longer use IP address to create server_id since some clouds use the same IP but forward using ports.

v1.1.8
------

- Updated lvm cookbook dependency version to 1.3.6.
- Set default filesystem on RHEL 7 platform_family to xfs.

v1.1.7
------

- On RHEL, depending on cloud, check and wait for RHEL repos to be installed.

v1.1.6
------

- Remove logic to ignore cloud/public_ips for server-id on cloudstack.

v1.1.5
------

- Ignore cloud/public_ips for server-id on cloudstack.

v1.1.4
------

- Use Upstart for the mysql service in decommission on Ubuntu 14.04.

v1.1.3
------

- Fix volume type input description since it is not just for vSphere.

v1.1.2
------

- Add kitchen testing for RHEL 6.5 and Ubuntu 14.04.
- Update versions of dependent cookbooks.
- Update testing code to abide by Serverspec v2.

v1.1.1
------

- Update the dependency versions of `rightscale_volume` and `rightscale_backup`, supporing VMware vSphere.
- Set `rs-mysql/device/volume_type` node attribute in metadata.
- Pass `rs-mysql/device/volume_type` and `rs-mysql/device/controller_type` to `rightscale_volume`.

v1.1.0
------

- Release to coincide with the v14.0.0 Beta ServerTemplates.

v1.0.0
------

- Initial release
