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
* `node['daris']['user_groups']` - The list of the "groups" of users to be created by the "users" recipe.
* `node['daris']['default_password']` - The default initial password for users.

You also need to:

* copy the "mfpkg*.zip" file containing your PSSD localization to the local installers location (e.g. ~mediaflux/installers), and
* add entry to the "pkgs" map; e.g. in the "node.json" file ...
      
      "daris": {
         "pkgs: {
            "cai_pssd": "mfpkg-cai_pssd-0.02-mf3.8.029.zip"
         },
         "ns": "cai"
      }

Creating users
==============

The "users" recipe will create initial DaRIS users based on the contents of the 
"daris_users" data bag.  To make use of this facility, you need to do the following:

1.  For each user, add a JSON descriptor file to the "data-bags/daris_users" directory.  A typical file would look like this:
        
        file:  humphrey.json
        ----------------
        {
            "id": "humphrey",
            "user": "hb",
            "domain": "users",
            "groups": [ "test-users" ],
            "names": [ "Humphrey", "B", "Bear" ],
            "email": "hbb@nws9.com.au",
            "project_creator": true,
            "password": "secret"
        }
        
    The attributes are as follows:
    * `'id'` - mandatory. This must match the filename.
    * `'name'` - optional. This gives the Mediaflux user name.  If it is omitted, `id` is used instead.
    * `'domain'` - optional.  This gives the Mediaflux domain for the user.  It defaults to `node['mediaflux']['authentication_domain']` which in turn defaults to `'users'`.
    * `'groups'` - mandatory.  A list of "group names".  The meaning of this is explained below.
    * `'names'`  - optional.  A list of names for the user in order "first" name, "middle" names, "last" name.  (If only one name is given, it is treated as a "first" name.)
    * `'email'` - mandatory.  The user's (external) email address.
    * `'project_creator'` - optional.  If true, the user has DaRIS project creation rights.
    * `'roles'` - optional. A list of additional Mediaflux "roles" to be granted to the user.  For example, you would typically grant one or more roles defined by the PSSD localization package.
    * `'password'` - optional.  The user's initial password.  If omitted, the initial password is given by the `node['daris']['default_password']` attribute.

1. In the node JSON file:

    * Add a 'daris' / 'user_groups' whose value is an array of "group names".
    * Add `"recipe[daris::users]"` to the node's runlist (after 

When the recipe is run, it selects all users which have a "group name" that is in the "user groups" list that you configured.  For each selected user, it attempts to create the DaRIS account (using `om.pssd.user.create`).  If the user account already exists in DaRIS, it is not updated.

DaRIS versions
==============

The current mechanism for determining what version of DaRIS to install, is fragile and clunky.  There is currently a mapping that lists the "known" versions of DaRIS and their respective components and version numbers.  This information is used to generate the URL pathnames for downloading the various ZIP files from the DaRIS download site.

The problem is two-fold:

*  The mapping of known versions is hard-wired into the recipe's ruby code: see "site-cookbooks/daris/libraries/daris_urls.rb".  It will break when there is a new "stable", and it does break when a version number changes in one of the "latest" components.

*  The download site only has the downloadables for the latest "latest" and for the current "stable".  If you needed some other version, you would need to email the DaRIS developers.  Obviously, that can't be scripted.

The way that the recipes currently deal with these issues is to cache the downloadables, and only attempt to re-download if we don't have a copy at all.  That means that the recipes don't normally pick up the latest versions of "latest" (for instance).  But at least, this way the recipes are like to work from one day to the next.

There are a couple of other things that you can do to work around these problems when necessary:

* If you have old copies of the required "installables", you can manually copy them into the "installers" cache directory.

* If you want to use a specific version of an installable rather the one that the "mappings" say, you can specify this using node attributes.  For example:
      
      "daris": {
          "pssd": "stable/mfpkg-pssd-2.03-mf3.8.029-stable.zip"
      },
      
  tells the recipe to use PSSD 2.03, irrespective of what the other component versions are.  (A download would likely fail, but that's a different issue.)

TO DO List
==========

* Deal with updating DaRIS with a fresh version.  For example, the simple-minded  scheme for deciding when to bootstrap doesn't take account of DaRIS versions, so it won't even try to upgrade the DaRIS packages.
* The implementation of DaRIS bootstrapping is ugly.  (Maybe it would be better to make it a single templatized shell script?)
* Figure out how to generate & record random initial user passwords.
