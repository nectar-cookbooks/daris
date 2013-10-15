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

if ! ::File.exists?( '/usr/local/bin/pvconv.pl' ) then
  include_recipe "pvconv"
end

mflux_home = node['mediaflux']['home']
mflux_user = node['mediaflux']['user']
mflux_user_home = node['mediaflux']['user_home']
url = node['daris']['download_url']
user = node['daris']['download_user']
password = node['daris']['download_password']
pkgs = node['daris']['pkgs']

installers = "#{mflux_home}/daris_installers"
mfcommand = "#{mflux_user_home}/bin/mfcommand"

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

