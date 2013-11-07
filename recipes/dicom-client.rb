#
# Cookbook Name:: daris
# Recipe:: dicom-client
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

include_recipe "daris::common"

::Chef::Recipe.send(:include, DarisUrls)

mflux_home = node['mediaflux']['home']
mflux_bin = node['mediaflux']['bin'] || "#{mflux_home}/bin"
mflux_user_home = node['mediaflux']['user_home'] || mflux_home
user = node['daris']['download_user']
password = node['daris']['download_password']

installers = node['mediaflux']['installers'] || 'installers'
if ! installers.start_with?('/') then
  installers = mflux_user_home + '/' + installers
end

dc_url = getUrl(node, 'dicom_client')
dc_file = urlToFile(dc_url)
bash "fetch-dicom-client" do
  user 'root'
  code "wget --user=#{user} --password=#{password} --no-check-certificate " +
       "-O #{installers}/#{dc_file} #{dc_url}"
  not_if { ::File.exists?("#{installers}/#{dc_file}") }
end

bash "extract-dicom-client" do
  cwd mflux_bin
  user 'root'
  code "unzip -o #{installers}/#{dc_file} dicom-client.jar"
end

cookbook_file "#{mflux_bin}/dicom-mf.sh" do
  owner 'root'
  mode 0755
  source "dicom-mf.sh"
end
