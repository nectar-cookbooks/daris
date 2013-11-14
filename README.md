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

* `daris::default` - installs DaRIS into a MediaFlux installation, along with some useful tools provided by the DaRIS team.
* `daris::daris` - installs just DaRIS into a MediaFlux installation.
* `daris::pvupload` - installs the Bruker upload tool.
* `daris::dicom-client` - installs the "dicom-mf" upload tool.
* `daris::users` - creates users from the "daris_users" databag.

Attributes
==========

See `attributes/default.rb` for the default values.

* `node['daris']['ns']` - This gives the namespace prefix for this installation's PSSD tailoring.
* `node['daris']['download_url']` - This gives the base URL for downloading DaRIS software.
* `node['daris']['version']` - This gives the DaRIS version
* `node['daris']['download_user']` - The account name for downloading from the DaRIS site.
* `node['daris']['download_password']` - The password for downloading from the DaRIS site.
* `node['daris']['force_bootstrap']` - If true (actually, "truthy"), the bootstrapping of the Mediaflux stores and DaRIS packages is forced.  If false, we only bootstrap if it looks like we have a fresh Mediaflux installation as created by the "mediaflux" recipe.  (We "sniff" the network.tcl file to figure this out.)
* `node['daris']['dicom_namespace']` - The namespace used for DICOM.
* `node['daris']['dicom_proxy_domain']` - The domain to be used for the DICOM proxy users.
* `node['daris']['dicom_proxy_user_names']` - A list of DICOM proxy users to be created.
* `node['daris']['dicom_ingest_notifications']` - A list of user emails to be notified of DICOM ingestion events.
* `node['daris']['user_groups'] - The list of the "groups" of users to be created by the "users" recipe.
* `node['daris']['default_password'] - The default initial password for users.

You also need to:

* copy the "mfpkg*.zip" file containing your PSSD localization to the local installers location (e.g. ~mediaflux/installers), and
* add entry to the "pkgs" map; e.g. in the "node.json" file ...

      "daris": {
         "pkgs: {
            "cai_pssd": "mfpkg-cai_pssd-0.02-mf3.8.029.zip"
         },
         "ns": "cai"
      }

TO DO List
==========

* Deal with updating DaRIS with a fresh version.  For example, the simple-minded  scheme for deciding when to bootstrap doesn't take account of DaRIS versions, so it won't even try to upgrade the DaRIS packages.
* The implementation of DaRIS bootstrapping is ugly.  (Maybe it would be better to make it a single templatized shell script?)
* Figure out how to generate & record random initial user passwords.