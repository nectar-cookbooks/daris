node.default['daris']['ns'] = 'nig'
node.default['daris']['file_system_type'] = 'file-system'
node.default['daris']['force_bootstrap'] = false
node.default['daris']['dicom_port'] = '6666'

node.default['daris']['download_url'] = 
  'https://daris-1.rvm.nectar.org.au:8443/daris-downloads/stable'
node.default['daris']['download_user'] = 'guest@www-public'
node.default['daris']['download_password'] = 'nIg4!871'

node.default['daris']['dicom_namespace'] = 'dicom'
node.default['daris']['dicom_store'] = 'dicom'
node.default['daris']['dicom_proxy_domain'] = 'dicom'
node.default['daris']['dicom_proxy_user_names'] = ['DICOM-TEST']
node.default['daris']['dicom_ingest_notifications'] = []

# The standard DaRIS packages.
node.default['daris']['pkgs']['nig_essentials'] = 
  'mfpkg-nig_essentials-0.19-mf3.8.029-stable.zip'
node.default['daris']['pkgs']['nig_transcoder'] = 
  'mfpkg-nig_transcode-0.33-mf3.8.029-stable.zip'
node.default['daris']['pkgs']['pssd'] = 
  'mfpkg-pssd-2.04-mf3.8.029-stable.zip'
node.default['daris']['pkgs']['daris_portal'] = 
  'mfpkg-daris-0.29-mf3.8.029-stable.zip'

# We install the "server-config.sh" tool by default, though 
# we don't actually use it in the setup procedure anymore.
node.default['daris']['server_config'] =
  'server-config-1.0-stable.zip'

# Additional tools that are installed by other recipes:
node.default['daris']['pvupload'] = 'pvupload-0.33-stable.zip'
node.default['daris']['dicomclient'] = 'dicom-client-1.0-stable.zip'
node.default['daris']['dcmtools'] = 'dcmtools-0.29-stable.zip'

node.override['mediaflux']['defer_start'] = true
