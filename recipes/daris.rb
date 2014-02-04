#
# Cookbook Name:: daris
# Recipe:: daris
#
# Copyright (c) 2013, 2014, The University of Queensland
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# * Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
# * Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
# * Neither the name of the The University of Queensland nor the
# names of its contributors may be used to endorse or promote products
# derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE UNIVERSITY OF QUEENSLAND BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

include_recipe "pvconv"
include_recipe "minc-toolkit"

include_recipe "daris::common"

::Chef::Recipe.send(:include, DarisUrls)

mflux_home = node['mediaflux']['home']
mflux_bin = node['mediaflux']['bin'] || "#{mflux_home}/bin"
mflux_config = "#{mflux_home}/config"
mflux_user = node['mediaflux']['user']
mflux_user_home = node['mediaflux']['user_home'] || mflux_home
url = node['daris']['download_url']
refresh = node['daris']['force_refresh'] || false
bootstrap = node['daris']['force_bootstrap'] || false

if unstableRelease?(node) && bootstrap then
  refresh = true
end

wget_opts = wgetOpts(node, refresh)

pkgs = {
  'nig_essentials' => buildDarisUrl(node, 'nig_essentials'),  
  'nig_transcode' => buildDarisUrl(node, 'nig_transcode'),  
  'pssd' => buildDarisUrl(node, 'pssd'),
  'daris_portal' => buildDarisUrl(node, 'daris_portal')
}

local_pkgs = node['daris']['local_pkgs'] || {}
all_pkgs = pkgs.merge(local_pkgs)
installers = node['mediaflux']['installers'] || 'installers'
if ! installers.start_with?('/') then
  installers = mflux_user_home + '/' + installers
end

ruby_block "check-preconditions" do
  block do
    if ! File::directory?("#{mflux_home}") then
      raise "Can't find the Mediaflux install directory #{mflux_home}. " +
        "Have you installed Mediaflux?"
    end
    if ! File::directory?("#{mflux_config}") then
      raise "Can't find the Mediaflux config directory #{mflux_config}. " +
        "Have you installed Mediaflux?"
    end
  end
end

mfcommand = "#{mflux_bin}/mfcommand"
pvconv = node['pvconv']['command']
dcm2mnc = (node['minc-toolkit']['prefix'] || '/usr/local') + '/bin/dcm2mnc'

dicom_store = node['daris']['dicom_store']
if ! dicom_store || dicom_store == '' then
  dicom_store = 'dicom'
end

template "#{mflux_config}/initial_daris_conf.tcl" do 
  source "initial_daris_conf_tcl.erb"
  owner mflux_user
  group mflux_user
  mode 0400
  helpers (MfluxHelpers)
  variables ({
               :dicom_proxy_domain => node['daris']['dicom_proxy_domain'],
               :dicom_proxy_user_names => node['daris']['dicom_proxy_user_names'],
               :dicom_ingest_notifications => node['daris']['dicom_ingest_notifications'],
               :ns => node['daris']['ns']
             })
end

template "#{mflux_config}/create_stores.tcl" do 
  source "create_stores_tcl.erb"
  owner mflux_user
  group mflux_user
  mode 0400
  helpers (MfluxHelpers)
  variables ({
               :dicom_namespace => node['daris']['dicom_namespace'],
               :dicom_store => dicom_store,
               :fs_type => node['daris']['file_system_type']
             })
end

pkgs.each() do | pkg, url | 
  file = darisUrlToFile(url)
  bash "fetch-#{pkg}" do
    user mflux_user
    code "wget #{wget_opts} -O #{installers}/#{file} #{url}"
    not_if { !refresh && File.exists?("#{installers}/#{file}") }
  end
end

local_pkgs.each() do | pkg, file | 
  ruby_block "check #{pkg} installer" do
    block do
      if ! ::File.exists?("#{installers}/#{file}") then
        raise "There is no installer for local package #{pkg}: " +
          "(expected #{installers}/#{file})" 
      end
    end
  end
end

directory "#{mflux_home}/plugin/bin" do
  owner mflux_user
  recursive true
end 

template "#{mflux_home}/plugin/bin/pvconv.pl" do
  owner mflux_user
  group mflux_user
  mode 0555
  source 'pvconv.erb'
  variables ({
    :pvconv_command => pvconv
  })
end

template "#{mflux_home}/plugin/bin/dcm2mnc" do
  owner mflux_user
  group mflux_user
  mode 0555
  source 'dcm2mnc.erb'
  variables ({
    :dcm2mnc_command => dcm2mnc
  })
end

sc_url = buildDarisUrl(node, 'server_config')
sc_file = darisUrlToFile(sc_url)

bash "fetch-server-config" do
  user mflux_user
  code "wget #{wget_opts} -O #{installers}/#{sc_file} #{sc_url}"
  not_if { !refresh && File.exists?("#{installers}/#{sc_file}") }
end

# We don't use this tool for configuration.  But someone might want to ...
bash 'extract-server-config' do
  cwd mflux_bin
  user 'root'
  code "unzip -o #{installers}/#{sc_file} server-config.jar"
end

cookbook_file "#{mflux_bin}/server-config.sh" do
  owner 'root'
  mode 0750
  source 'server-config.sh'
end

ruby_block "bootstrap_test" do
  block do
    if ! bootstrap then
      # Sniff the 'network.tcl' for evidence that we created it ...
      line = `grep Generated #{mflux_config}/services/network.tcl`.strip()
      if /Mediaflux chef recipe/.match(line) then
        bootstrap = true
      elsif /DaRIS chef recipe/.match(line) then
        bootstrap = false
      else
        # Badness.  Bail now before we do any more damage.
        raise "Unrecognized signature in the network.tcl file (#{line}). " +
          "Bailing out to avoid clobbering hand-made Mediaflux configs."
      end
    end
    if bootstrap then
      # It appears that if you use run_action like this, triggering
      # doesn't work.  But it is simpler this way anyway
      resources(:log => "bootstrap").run_action(:write)
      resources(:bash => "mediaflux-running").run_action(:run)
      resources(:bash => "create-stores").run_action(:run)
      all_pkgs.each() do | pkg, file | 
        resources(:bash => "install-#{pkg}").run_action(:run)
      end
      resources(:template => "#{mflux_config}/services/network.tcl")
        .run_action(:create)
      resources(:service => "mediaflux-restart").run_action(:restart)
    else
      resources(:log => "no-bootstrap").run_action(:write)
    end
  end
end

# The deal here is that when we are bootstrapping DaRIS into a clean
# Mediaflux system, it won't have the "dicom" listener in network.tcl.
# We have to: 1) start Mediaflux, 2) create the stores, 3) add the
# DaRIS packages, 4) update network.tcl and restart Mediaflux.
log "bootstrap" do
  action :nothing
  message "Bootstrapping the DaRIS stores and plugins."
  level :info
end

log "no-bootstrap" do
  action :nothing
  message "Skipped bootstrapping the DaRIS stores and plugins."
  level :info
end

service "mediaflux-restart" do
  action :nothing
  service_name "mediaflux"
end

bash "mediaflux-running" do
  action :nothing
  user mflux_user
  code ". /etc/mediaflux/mfluxrc ; " +
    "wget ${MFLUX_TRANSPORT}://${MFLUX_HOST}:${MFLUX_PORT}/ " +
    "    --retry-connrefused --no-check-certificate -O /dev/null " +
    "    --secure-protocol=SSLv3 --waitretry=1 --timeout=2 --tries=30"
end 

bash "create-stores" do
  action :nothing
  user "root"
  code ". /etc/mediaflux/servicerc && " +
    "#{mfcommand} logon $MFLUX_DOMAIN $MFLUX_USER $MFLUX_PASSWORD && " +
    "#{mfcommand} source #{mflux_config}/create_stores.tcl && " +
    "#{mfcommand} logoff"
  not_if { ::File.exists?("#{mflux_home}/volatile/stores/pssd") &&
           ::File.exists?("#{mflux_home}/volatile/stores/#{dicom_store}") }
end

# Add the pssd and dicom stores to the set of stores to be backed up
backup_tcl = resources("template[backup.tcl]")
all_stores = backup_tcl.variables['stores']
if !all_stores.include?('pssd') then
   all_stores << 'pssd'
end
if !all_stores.include?(dicom_store) then
   all_stores << dicom_store
end

all_pkgs.each() do | pkg, url |
  file = darisUrlToFile(url) 
  bash "install-#{pkg}" do
    action :nothing
    user "root"
    code ". /etc/mediaflux/servicerc && " +
      "#{mfcommand} logon $MFLUX_DOMAIN $MFLUX_USER $MFLUX_PASSWORD && " +
      "#{mfcommand} package.install :in file:#{installers}/#{file} && " +
      "#{mfcommand} logoff"
  end
end 
  
template "#{mflux_config}/services/network.tcl" do 
  action :nothing
  owner mflux_user
  source "network-tcl.erb"
    variables({
                :http_port => node['mediaflux']['http_port'],
                :https_port => node['mediaflux']['https_port'],
                :dicom_port => node['daris']['dicom_port']
              })
  end

bash "mediaflux-running-2" do
  user mflux_user
  code ". /etc/mediaflux/mfluxrc ; " +
    "wget ${MFLUX_TRANSPORT}://${MFLUX_HOST}:${MFLUX_PORT}/ " +
    "    --retry-connrefused --no-check-certificate -O /dev/null " +
    "    --secure-protocol=SSLv3 --waitretry=1 --timeout=2 --tries=20"
end

bash "run-initial-daris-config" do
  code ". /etc/mediaflux/servicerc && " +
         "#{mfcommand} logon $MFLUX_DOMAIN $MFLUX_USER $MFLUX_PASSWORD && " +
         "#{mfcommand} source #{mflux_config}/initial_daris_conf.tcl && " +
         "#{mfcommand} logoff"
end
