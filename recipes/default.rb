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

installers = node['mediaflux']['installers']
if ! installers.start_with?('/') then
  installers = mflux_user_home + '/' + installers
end

mfcommand = "#{mflux_user_home}/bin/mfcommand"
pvconv = node['pvconv']['command']

package "wget" do
  action :install
  not_if { ::File.exists?("/usr/bin/xauth") }
end

directory installers do
  owner mflux_user
end

['pssd', 'dicom'].each() do |store| 
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
  bash "fetch-#{pkg}" do
    user mflux_user
    code "wget --user=#{user} --password=#{password} --no-check-certificate " +
         "-O #{installers}/#{file} #{url}/#{file}"
    not_if { ::File.exists?("#{installers}/#{file}") }
  end
  bash "install-#{pkg}" do
    user "root"
    code ". /etc/mediaflux/servicerc && " +
         "#{mfcommand} logon $MFLUX_DOMAIN $MFLUX_USER $MFLUX_PASSWORD && " +
         "#{mfcommand} package.install :in file:#{installers}/#{file} && " +
         "#{mfcommand} logoff"
  end
end 

# I don't think this is necessary when using mfcommand ...
if false then
  bash "srefresh" do
    user "root"
    code ". /etc/mediaflux/servicerc && " +
         "#{mfcommand} logon $MFLUX_DOMAIN $MFLUX_USER $MFLUX_PASSWORD && " +
         "#{mfcommand} srefresh && " +
         "#{mfcommand} logoff"
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

def java_memory_model() do
  version = `java -version`
  if /.*64-BIT.*/.matches(version) then '64'
  elsif /.*32-BIT.*/.matches(version) then '32'
  else raise 'Cannot figure out memory model for java' end
end

def java_memory_max(arg) do
  if arg && arg != '' then
    max_memory = int(arg)
    if max_memory < 128 then
      raise 'The JVM max memory size is too small'
    end
  else
    # Intuit a sensible memory size from the platform and the available memory.
    if java_memory_model() == '32' then
      max_memory = if platform?("windows") then 1500 else 2048 end
    else
      max_memory = (/([0-9]+)kB/.match(node['memory']['total'])[1] / 1024) - 512
    end
  end
  return max_memory
end

template "#{mflux_user_home}/initial_daris_conf" do 
  source "initial_daris_conf.erb"
  owner mflux_user
  group mflux_user
  mode 0400
  variables ({
    password => node['mediaflux']['admin_password'],
    server_name => node['mediaflux']['server_name'],
    server_organization => node['mediaflux']['server_organization'],
    jvm_memory_max => node['mediaflux']['jvm_memory_max'],
    jvm_memory_perm_max => node['mediaflux']['jvm_memory_max'],
    mail_smtp_host => node['mediaflux']['mail_smtp_host'],
    mail_smtp_port => node['mediaflux']['mail_smtp_port'],
    mail_from => node['mediaflux']['mail_from'],
    notification_from => node['mediaflux']['notification_from'],
    authentication_domain => node['mediaflux']['authentication_domain'],
    dicom_namespace => node['daris']['dicom_domain'],
    dicom_store => node['daris']['dicom_store'],
    dicom_proxy_domain => node['daris']['dicom_proxy_domain'],
    dicom_proxy_user_names => node['daris']['dicom_proxy_user_names'],
    dicom_notifications => node['daris']['dicom_ingest_notifications']
  })
end

bash "run-server-config" do
  user mflux_user
  group mflux_user
  code "#{mflux_user_home}/bin/server-config.sh " +
       "    < #{mflux_user_home}/initial_daris_conf"
end
