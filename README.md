Overview
========

This cookbook is for installing DaRIS in a MediaFlux instance.

Dependencies
============

DaRIS is a set of plugins for MediaFlux.  Hence a Mediaflux installation 
and license are dependencies.

The recipes in this cookbook should work on x86 and x86-64 systems running
recent Ubuntu, RHEL compatible and Fedora distros (at least).  Windows is
is not supported.

Recipes
=======

* `daris::default` - installs DaRIS into a MediaFlux installation, along with some useful tools provided by the DaRIS team.
* `daris::daris` - installs just DaRIS into a MediaFlux installation.
* `daris::pvupload` - installs the Bruker upload tool.
* `daris::dicom-client` - installs the "dicom-mf" upload tool.
* `daris::users` - creates users from the "daris_users" databag.
* `daris::dicom-hosts` - creates DICOM proxy users from the "dicom_hosts" databag.
* `daris::build_daris` - checks out and does a local build of the DaRIS portal component.
* `daris::build_nigtk` - checks out and does a local build of the NIGTK components.
* `daris::build_transform` - checks out and does a local build of the Transform component.

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

There are other "advanced" attributes that relate to local builds and using the resulting components; see "Using the build recipes" below.

You also need to:

* copy the "mfpkg*.zip" file containing your PSSD localization to the local installers location (e.g. ~mediaflux/installers), and
* add entry to the "pkgs" map; e.g. in the "node.json" file ...
``` 
        "daris": {
           "pkgs: {
              "cai_pssd": "mfpkg-cai_pssd-0.02-mf3.8.029.zip"
           },
           "ns": "cai"
        }
```

Creating users
==============

The "daris::users" recipe will create initial DaRIS users based on the contents of the 
"daris_users" data bag.  To make use of this facility, you need to do the following:

Step 1:  For each user, add a JSON descriptor file to the "data-bags/daris_users" directory.  A typical file would look like this:
```
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
```
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

Step 2: In the node JSON file:

  * Add a 'daris' / 'user_groups' whose value is an array of "group names".
  * Add `"recipe[daris::users]"` to the node's runlist (after 

When the recipe is run, it selects all users which have a "group name" that is in the "user groups" list that you configured.  For each selected user, it attempts to create the DaRIS account (using `om.pssd.user.create`).  If the user account already exists in DaRIS, it is not updated.

DICOM Hosts
===========

The "daris::dicom-hosts" recipe uses the information in the "dicom_hosts" data bag to do two things:

* It creates a "proxy user" accounts in the DICOM authentication domain with roles that allow upload of data by dicom clients.

* If `node['daris']['manage_firewall']` is true, it will create local firewall rules to allow the DICOM hosts to connect using the DICOM port.

A typical "dicom-hosts" databag entry looks like this:
```
        file: imager.json
        ----------------
        {
            "id": "imager",
            "name": "imager",
            "hostname": "imager.example.com",
            "port": "6666"
        }
```
The attributes are as follows:
  * `'id'` - mandatory. This must match the filename.
  * `'name'` - optional. This gives the proxy user name.  If it is omitted, `id` is used instead.
  * `'hostname'` - optional.  This gives hostname for the firewall entry.
  * `'port'` - optional.  This gives the port number for the firewall entry; defaults to `node['daris']['dicom_port']` which in turn defaults to "6666".

Note that firewall management is not yet implemented because the standard recipies for firewall management are currently Debian / Ubuntu specific.

Meanwhile, if you are using a NeCTAR virtual, we recommend that you manage the firewall externally; i.e. via the Dashboard.

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

Using the build recipes
=======================

The "daris::build_*" recipes are designed for situations where you need to
make a local build of the DaRIS components instead of downloading them.  
To use them, you will need to ask the DaRIS project administrators to 
provide you with the repository URLs.  They are currently private, but 
read access is typically granted on request.  (Open access is on the agenda,
but certain things need to be sorted out first.)

The build recipes checkout from the relevant DaRIS project Git repositories,
run the respective builds, and then copy the built components into the local
installer cache directory.  However, there is a slight snag.  The build 
scripts create the components with different names to the ones used on the
download site.  (This is arguably a good thing ...).  So, if you want to
use the downloadables, you need to set these attributes:

* `node['daris']['release']` - This must be set to "latest".
* `node['daris']['use_local_daris_builds']` - This must be "true".

The following attributes also apply:

* `node['daris']['nigtk_repo']` - The url of the NIGTK git repository.
* `node['daris']['nigtk_branch']` -The NIGTK branch to use; defaults to "master".
* `node['daris']['transform_repo']` - The url of the Transform git repository.
* `node['daris']['transform_branch']` - The Transform branch to use; defaults to "master".
* `node['daris']['daris_repo']` - The url of the DaRIS git repository.
* `node['daris']['daris_branch']` - The DaRIS branch to use; defaults to "master".
* 
* `node['daris']['private_key_file']` - The name of an SSH private key file for git checkouts.  It is convenient (but less secure) if the key file doesn't have a pass phrase.  Defaults to 'nil' which means that no private key is used.  (This should work in the future when DaRIS becomes fully open-source.)
* `node['daris']['build_tree']` - The directory in which checkouts and builds are performed.  Defaults to "/tmp/daris-build".

Finally, you need to ensure that the 'daris::build_*' recipes are run before the 'daris::daris' recipe.

Extension packages
==================

DaRIS provides some additional packages that do not need to be installed by 
default:

  * The "sinks" package defines some new Mediaflux sinks for importing and 
    exporting files.  The "owncloud" sink type allows you to communicate
    with a service such as AARNET's "sloudstor+".  The "scp/ssh" sink allows
    you to import and export files using SCP.

  * The "transform" package allows you to integrate external processing
    of objects (e.g. using Kepler workflows) into DaRIS.
  
Both of these packages are currently "experimental", and only available via
the DaRIS source-code repositories.  To include them you need to use the
"build::nigtk", "build::daris" and/or "build::transform" recipes to do
a local checkout and build (see above).

If you want the resulting packages to be loaded during the DaRIS bootstrap,
you need to set these attributes:

* `node['daris']['load_sinks']` - Set to 'true' to load the "sinks" package.
* `node['daris']['load_transform']` - Set to 'true' to load the "transform" 
  package.

DaRIS Commands
==============

The main "daris::daris" recipe installs a couple of shell commands into the 
Mediaflux bin directory:

  * The "mfsink" command is used for configuring generic and DaRIS specific
    "sinks".
  * The "keplerconfig" command is used for configuring the DaRIS / Kepler
    workflow integration.

Both of these command must be run as the "mflux" user, as they require 
Mediaflux admin privilege.

Note: these commands work by running Mediaflux Tcl scripts.  If something 
does wrong, you are likely to see an ugly Mediaflux stacktrace.  This is 
unfortunate, but it would difficult to extract decent diagnostics from 
the script output. 

The mfsink command
------------------

The "mfsink" command allows you to create, remove, list and describe the
Mediaflux data sink configurations.  

The primary command documentation is provided by the "help" subcommand.

  * `mfsink help` lists the subcommands.
  * `mfsink help <subcommand>` gives help for the subcommand.

Here are a couple of examples:

```
    mfsink add my-sink scp   # defines a 'generic' SCP sink
    mfsink add my-cvl scp --host xxx.xxx.xxx.xxx --pk-key pk-cvl
                             # defines a sink for a specific host
			     # using a private key in the user's wallet
```

Note that the mfsink command allows you to embed credentials into a sink
definition.  You should use this facility with caution because it has 
serious security implications:

  * Any embedded credentials will be visible to any user with mediaflux
    administrator privilege (or 'root' access).
  
  * Any embedded credentials will stored in the Mediaflux database in 
    the clear.
  
  * An sink with embedded credentials could be used by any DaRIS / Mediaflux
    user.

It is difficult to envisage a case in which embedding credentials into
sink configurations is a good idea.  The only case might be when the
sink writes to a shared file store where there ar no individual accounts
and anyone is permitted to see or overwrite anybody else's files.