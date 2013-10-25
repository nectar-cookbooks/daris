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

* `node['daris']['download_url']` - This gives the base URL for downloading DaRIS software.
* `node['daris']['version']` - This gives the DaRIS version
* `node['daris']['download_user']` - The account name for downloading from the DaRIS site.
* `node['daris']['download_password']` - The password for downloading from the DaRIS site.
* `node['mediaflux']['server_name']` - The name of the DaRIS server
* `node['mediaflux']['server_organization']` - The organization string for the server
* `node['mediaflux']['mail_smtp_host']` - The mail relay host for sending mail.
* `node['mediaflux']['mail_smtp_port']` - The corresponding port.
* `node['mediaflux']['mail_from']` - The "from:" address for regular mail sent by the server.
* `node['mediaflux']['notification_from']` - The "from:" address for notifications.
* `node['mediaflux']['authentication_domain']` - A Mediaflux authentication domain name for users.  Set this if you want to create a custom local domain for user accounts.
* `node['mediaflux']['jvm_memory_max']` - The server's heap size (in Mbytes)
* `node['mediaflux']['jvm_memory_perm_max']` - The server's permgen size (in Mbytes)
* `node['daris']['dicom_namespace']` - The namespace used for DICOM.
* `node['daris']['dicom_proxy_domain']` - The domain to be used for the DICOM proxy users.
* `node['daris']['dicom_proxy_user_names']` - A list of DICOM proxy users to be created.
* `node['daris']['dicom_ingest_notifications']` - A list of user emails to be notified of DICOM ingestion events.