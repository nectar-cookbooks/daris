node.default['daris']['ns'] = 'nig'
node.default['daris']['file_system_type'] = 'file-system'

# If you set force-bootstrap, the DaRIS packages are loaded, even if
# this doesn't look like a fresh install.
node.default['daris']['force_bootstrap'] = false
node.default['daris']['dicom_port'] = '6666'

node.default['daris']['download_url'] = 
  'https://daris-1.rvm.nectar.org.au:8443/daris-downloads'
node.default['daris']['download_dir'] = 'stable' 
node.default['daris']['download_user'] = 'guest@www-public'
node.default['daris']['download_password'] = 'nIg4!871'

node.default['daris']['dicom_namespace'] = 'dicom'
node.default['daris']['dicom_store'] = 'dicom'
node.default['daris']['dicom_proxy_domain'] = 'dicom'
node.default['daris']['dicom_proxy_user_names'] = ['DICOM-TEST']
node.default['daris']['dicom_ingest_notifications'] = []

# These attributes give specific versions of the downloadables.  If
# they are not set (e.g. in the Node, Role or Recipe) then they
# are generated using templates and the 'releases' map.
node.default['daris']['release'] = 'stable-2-18'
node.default['daris']['download_dir'] = nil 
node.default['daris']['nig_essentials'] = nil
node.default['daris']['nig_transcoder'] = nil
node.default['daris']['pssd'] = nil
node.default['daris']['daris_portal'] = nil
node.default['daris']['pvupload'] = nil
node.default['daris']['dicom-client'] = nil
node.default['daris']['dcmtools'] = nil

# Local packages.  These WON'T be downloaded.
node.default['daris']['local_pkgs'] = {}

# We install the "server-config.sh" tool by default, though 
# we don't actually use it in the setup procedure anymore.
node.default['daris']['server_config'] =
  'server-config-1.0-stable.zip'

# Additional tools (optional)
node.default['daris']['pvupload'] = 'pvupload-0.33-stable.zip'
node.default['daris']['dicom-client'] = 'dicom-client-1.0-stable.zip'
node.default['daris']['dcmtools'] = 'dcmtools-0.29-stable.zip'

node.override['mediaflux']['defer_start'] = true
