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

mflux_home = node['mediaflux']['home']
mflux_user = node['mediaflux']['user']
mflux_user_home = node['mediaflux']['user_home']
url = node['daris']['download_url']
user = node['daris']['download_user']
password = node['daris']['download_password']
pkgs = node['daris']['pkgs']

if ! File::directory?("#{mflux_home}") then
  raise "Cannot find the Mediaflux install directory #{mflux_home}. " +
    "Have you installed Mediaflux?"
end
if ! File::directory?("#{mflux_home}/config") then
  raise "Cannot find the Mediaflux config directory #{mflux_home}/config. " +
    "Have you installed Mediaflux?"
end

installers = node['mediaflux']['installers']
if ! installers.start_with?('/') then
  installers = mflux_user_home + '/' + installers
end

mfcommand = "#{mflux_user_home}/bin/mfcommand"
pvconv = node['pvconv']['command']

dicom_store = node['daris']['dicom_store']
if ! dicom_store || dicom_store == '' then
  dicom_store = 'dicom'
end

template "#{mflux_user_home}/initial_daris_conf.tcl" do 
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
    :authentication_domain => node['mediaflux']['authentication_domain'],
    :dicom_namespace => node['daris']['dicom_namespace'],
    :dicom_store => dicom_store,
    :dicom_proxy_domain => node['daris']['dicom_proxy_domain'],
    :dicom_proxy_user_names => node['daris']['dicom_proxy_user_names'],
    :dicom_ingest_notifications => node['daris']['dicom_ingest_notifications'],
    :ns => node['daris']['ns']
  })
end

package "wget" do
  action :install
  not_if { ::File.exists?("/usr/bin/wget") }
end

directory installers do
  owner mflux_user
end

pkgs.each() do | pkg, file | 
  bash "fetch-#{pkg}" do
    user mflux_user
    code "wget --user=#{user} --password=#{password} --no-check-certificate " +
         "-O #{installers}/#{file} #{url}/#{file}"
    not_if { ::File.exists?("#{installers}/#{file}") }
  end
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

package "unzip" do
  action :install
  not_if { ::File.exists?('/usr/bin/unzip') }
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

bootstrap_dicom = node['daris']['force_bootstrap']
if ! bootstrap_dicom then
  line = `grep Generated #{mflux_home}/config/network.tcl`.trim()
  if /Mediaflux chef recipe/.match(line) then
    bootstrap = true
  elsif /DaRIS chef recipe/.match(line) then
    bootstrap = false
  else
    raise "Don't recognize the signature in the network.tcl file."  
  end
end

# The deal here is that when we are bootstrapping DaRIS into a clean
# Mediaflux system, it won't have the "dicom" listener in network.tcl.
# We have to: 1) start Mediaflux, 2) create the stores, 3) add the
# DaRIS packages, 4) update network.tcl and restart Mediaflux.
if bootstrap_dicom then
  service "mediaflux-restart" do
    service_name "mediaflux"
    action :restart
  end
  
  bash "mediaflux-running" do
    user mflux_user
    code ". /etc/mediaflux/mfluxrc ; " +
      "wget ${MFLUX_TRANSPORT}://${MFLUX_HOST}:${MFLUX_PORT}/ " +
      "    --retry-connrefused --no-check-certificate -O /dev/null " +
      "    --waitretry=1 --timeout=2 --tries=10"
  end 
  
  ['pssd', dicom_store ].each() do |store| 
    bash "create-#{store}-store" do
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
      user "root"
      code ". /etc/mediaflux/servicerc && " +
        "#{mfcommand} logon $MFLUX_DOMAIN $MFLUX_USER $MFLUX_PASSWORD && " +
        "#{mfcommand} package.install :in file:#{installers}/#{file} && " +
        "#{mfcommand} logoff"
    end
  end 
  
  template "#{mflux_home}/config/services/network.tcl" do 
    owner mflux_user
    source "network-tcl.erb"
    variables({
                :http_port => node['mediaflux']['http_port'],
                :https_port => node['mediaflux']['https_port'],
                :dicom_port => node['daris']['dicom_port']
              })
  end
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
         "#{mfcommand} source #{mflux_user_home}/initial_daris_conf.tcl && " +
         "#{mfcommand} logoff"
end
