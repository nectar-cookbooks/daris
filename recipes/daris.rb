#
# Cookbook Name:: daris
# Recipe:: default
#
# Copyright (c) 2013, The University of Queensland
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

include_recipe "daris::common"

mflux_home = node['mediaflux']['home']
mflux_bin = node['mediaflux']['bin'] || "#{mflux_home}/bin"
mflux_user = node['mediaflux']['user']
mflux_user_home = node['mediaflux']['user_home'] || mflux_home
url = node['daris']['download_url']
user = node['daris']['download_user']
password = node['daris']['download_password']

pkgs = node['daris']['pkgs']
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
    if ! File::directory?("#{mflux_home}/config") then
      raise "Can't find the Mediaflux config directory #{mflux_home}/config. " +
        "Have you installed Mediaflux?"
    end
  end
end

mfcommand = "#{mflux_bin}/mfcommand"
pvconv = node['pvconv']['command']

dicom_store = node['daris']['dicom_store']
if ! dicom_store || dicom_store == '' then
  dicom_store = 'dicom'
end

domain = node['mediaflux']['authentication_domain']
if ! domain || domain == '' then
  domain = node['daris']['ns'] 
end

template "#{mflux_home}/config/initial_daris_conf.tcl" do 
  source "initial_daris_conf_tcl.erb"
  owner mflux_user
  group mflux_user
  mode 0400
  helpers (DarisHelpers)
  variables ({
               :password => node['mediaflux']['admin_password'],
               :server_name => node['mediaflux']['server_name'],
               :server_organization => node['mediaflux']['server_organization'],
               :jvm_memory_max => node['mediaflux']['jvm_memory_max'],
               :jvm_memory_perm_max => node['mediaflux']['jvm_memory_max'],
               :mail_smtp_host => node['mediaflux']['mail_smtp_host'],
               :mail_smtp_port => node['mediaflux']['mail_smtp_port'],
               :mail_from => node['mediaflux']['mail_from'],
               :notification_from => node['mediaflux']['notification_from'],
               :authentication_domain => domain,
               :dicom_namespace => node['daris']['dicom_namespace'],
               :dicom_store => dicom_store,
               :dicom_proxy_domain => node['daris']['dicom_proxy_domain'],
               :dicom_proxy_user_names => node['daris']['dicom_proxy_user_names'],
               :dicom_ingest_notifications => node['daris']['dicom_ingest_notifications'],
               :ns => node['daris']['ns']
             })
end

pkgs.each() do | pkg, file | 
  bash "fetch-#{pkg}" do
    user mflux_user
    code "wget --user=#{user} --password=#{password} --no-check-certificate " +
         "-O #{installers}/#{file} #{url}/#{file}"
    not_if { ::File.exists?("#{installers}/#{file}") }
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

file = node.default['daris']['server_config']
bash "fetch-server-config" do
  user mflux_user
  code "wget --user=#{user} --password=#{password} --no-check-certificate " +
       "-O #{installers}/#{file} #{url}/#{file}"
  not_if { ::File.exists?("#{installers}/#{file}") }
end

bash "extract-server-config" do
  cwd "#{mflux_user_home}/bin"
  user mflux_user
  group mflux_user
  code "unzip -o #{installers}/#{file} server-config.jar"
end

cookbook_file "#{mflux_user_home}/bin/server-config.sh" do
  owner mflux_user
  group mflux_user
  mode 0750
  source "server-config.sh"
end

ruby_block "bootstrap_test" do
  block do
    bootstrap = node['daris']['force_bootstrap']
    if ! bootstrap then
      # Sniff the 'network.tcl' for evidence that we created it ...
      line = `grep Generated #{mflux_home}/config/services/network.tcl`.strip()
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
      resources(:service => "mediaflux-restart").run_action(:restart)
      resources(:bash => "mediaflux-running").run_action(:run)
      resources(:bash => "create-pssd-store").run_action(:run)
      resources(:bash => "create-#{dicom_store}-store").run_action(:run)
      pkgs.each() do | pkg, file | 
        resources(:bash => "install-#{pkg}").run_action(:run)
      end
      resources(:template => "#{mflux_home}/config/services/network.tcl")
        .run_action(:create)
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
    "    --waitretry=1 --timeout=2 --tries=10"
end 

['pssd', dicom_store ].each() do |store| 
  bash "create-#{store}-store" do
    action :nothing
    user "root"
    code ". /etc/mediaflux/servicerc && " +
      "#{mfcommand} logon $MFLUX_DOMAIN $MFLUX_USER $MFLUX_PASSWORD && " +
      "#{mfcommand} asset.store.create :name #{store} :local true " +
      "    :type #{node['daris']['file_system_type']} " +
      "    :automount true  && " +
      "#{mfcommand} logoff"
    not_if { ::File.exists?( "#{mflux_home}/volatile/stores/#{store}" ) }
  end
end

pkgs.each() do | pkg, file | 
  bash "install-#{pkg}" do
    action :nothing
    user "root"
    code ". /etc/mediaflux/servicerc && " +
      "#{mfcommand} logon $MFLUX_DOMAIN $MFLUX_USER $MFLUX_PASSWORD && " +
      "#{mfcommand} package.install :in file:#{installers}/#{file} && " +
      "#{mfcommand} logoff"
  end
end 
  
template "#{mflux_home}/config/services/network.tcl" do 
  action :nothing
  owner mflux_user
  source "network-tcl.erb"
    variables({
                :http_port => node['mediaflux']['http_port'],
                :https_port => node['mediaflux']['https_port'],
                :dicom_port => node['daris']['dicom_port']
              })
  end

service "mediaflux-restart-2" do
  service_name "mediaflux"
  action :restart
end

bash "mediaflux-running-2" do
  user mflux_user
  code ". /etc/mediaflux/mfluxrc ; " +
    "wget ${MFLUX_TRANSPORT}://${MFLUX_HOST}:${MFLUX_PORT}/ " +
    "    --retry-connrefused --no-check-certificate -O /dev/null " +
    "    --waitretry=1 --timeout=2 --tries=10"
end

bash "run-server-config" do
  code ". /etc/mediaflux/servicerc && " +
         "#{mfcommand} logon $MFLUX_DOMAIN $MFLUX_USER $MFLUX_PASSWORD && " +
         "#{mfcommand} source #{mflux_home}/config/initial_daris_conf.tcl && " +
         "#{mfcommand} logoff"
end

