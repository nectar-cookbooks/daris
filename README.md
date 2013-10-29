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
* `daris::pvupload` - installs the Bruker upload tool.

Attributes
==========

See `attributes/default.rb` for the default values.

* `node['daris']['download_url']` - This gives the base URL for downloading DaRIS software.
* `node['daris']['version']` - This gives the DaRIS version
* `node['daris']['download_user']` - The account name for downloading from the DaRIS site.
* `node['daris']['download_password']` - The password for downloading from the DaRIS site.
* `node['daris']['force_bootstrap']` - If true (actually, "truthy"), the bootstrapping of the Mediaflux stores and DaRIS packages is forced.  If false, we only bootstrap if it looks like we have a fresh Mediaflux installation as created by the "mediaflux" recipe.  (We "sniff" the network.tcl file to figure this out.)
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

TO DO List
==========

* Deal with updating DaRIS with a fresh version.  For example, the simple-minded  scheme for deciding when to bootstrap doesn't take account of DaRIS versions, so it won't even try to upgrade the DaRIS packages.
* The implementation of DaRIS bootstrapping is ugly.  (Maybe it would be better to make it a single templatized shell script?)