rs-mysql Cookbook CHANGELOG
=======================

This file is used to list changes made in each version of the rs-mysql cookbook.

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
