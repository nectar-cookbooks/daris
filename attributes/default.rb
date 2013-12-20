node.default['daris']['ns'] = 'nig'
node.default['daris']['file_system_type'] = 'file-system'

# If you set force-bootstrap, the DaRIS packages are loaded, even if
# this doesn't look like a fresh install.
node.default['daris']['force_bootstrap'] = false
node.default['daris']['dicom_port'] = '6666'

node.default['daris']['download_url'] = 
  'https://daris-1.melbourne.nectar.org.au:8443/daris-downloads'
node.default['daris']['download_dir'] = 'stable' 
node.default['daris']['download_user'] = 'guest@www-public'
node.default['daris']['download_password'] = 'nIg4!871'

# Normally, the recipes only download installers that we don't have 
# local copies of (based on the filenames).  Setting 'force_refresh'
# will cause the recipe to download if the timestamp has changed.
# (For the "latest" downloadables, the timestamps will change
# on each daily build.)
node.default['daris']['download_password'] = 'nIg4!871'

node.default['daris']['dicom_namespace'] = 'dicom'
node.default['daris']['dicom_store'] = 'dicom'
node.default['daris']['dicom_proxy_domain'] = 'dicom'
node.default['daris']['dicom_proxy_user_names'] = ['DICOM-TEST']
node.default['daris']['dicom_ingest_notifications'] = []
node.default['daris']['manage_firewall'] = false

# These attributes give specific versions of the downloadables.  If
# they are not set (e.g. in the Node, Role or Recipe) then they
# are generated using templates and the 'releases' map.
node.default['daris']['release'] = 'stable-2-18'
node.default['daris']['download_dir'] = nil 
node.default['daris']['nig_essentials'] = nil
node.default['daris']['nig_transcode'] = nil
node.default['daris']['pssd'] = nil
node.default['daris']['daris_portal'] = nil
node.default['daris']['pvupload'] = nil
node.default['daris']['dicom_client'] = nil
node.default['daris']['dcmtools'] = nil

# Local packages.  These WON'T be downloaded.
node.default['daris']['local_pkgs'] = {}

#node.override['mediaflux']['defer_start'] = true
