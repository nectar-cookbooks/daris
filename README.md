Overview
========

This cookbook is for installing DaRIS in a MediaFlux instance.

Dependencies
============

DaRIS is a set of plugins for MediaFlux.

This cookbook should in theory be platform independent ... across unix-like 
OSes.

Recipes
=======

* `daris::default` - installs DaRIS into a MediaFlux installation, along with some useful tools recommended by the DaRIS team.

Attributes
==========

See `attributes/default.rb` for the default values.

* `node['daris']['download_url']` - 
* `node['daris']['version']` -
* `node['daris']['download_user']` - 
* `node['daris']['download_password']` - 
* `node['mediaflux']['server_name']` -
* `node['mediaflux']['server_organization']` -
* `node['mediaflux']['server_organization']` -
* `node['mediaflux']['mail_smtp_host']` -
* `node['mediaflux']['mail_smtp_port']` -
* `node['mediaflux']['mail_from']` -
* `node['mediaflux']['notification_from']` -
* `node['mediaflux']['authentication_domain']` -

* `node['mediaflux']['jvm_memory_max']` -
* `node['mediaflux']['jvm_memory_perm_max']` -

