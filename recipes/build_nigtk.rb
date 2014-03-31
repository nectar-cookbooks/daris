#
# Cookbook Name:: daris
# Recipe:: build_nigtk
#
# Copyright (c) 2014, The University of Queensland
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

include_recipe 'java'

::Chef::Recipe.send(:include, DarisUrls)

build_tree = File.absolute_path(node['daris']['build_tree'])
dir = "#{build_tree}/git/nigtk"

mflux_home = node['mediaflux']['home']
mflux_user = node['mediaflux']['user']
installers = node['mediaflux']['installers'] || 'installers'
if ! installers.start_with?('/') then
  installers = mflux_user_home + '/' + installers
end
refresh = node['daris']['force_refresh'] || false

package "ant" do
end

private_key_file = node['daris']['private_key_file']
if private_key_file then
  template "#{build_tree}/ssh_wrapper.sh" do
    source "ssh_wrapper.sh.erb"
    variables ({"private_key_file" => private_key_file})
    mode 0755
  end 
end

git dir do
  repository node['daris']['nigtk_repo']
  revision node['daris']['nigtk_branch']
  ssh_wrapper "#{build_tree}/ssh_wrapper.sh" if private_key_file
end

bash "build nigtk" do
  code "ant build-all"
  cwd dir
end

BUILT_COMPONENTS = 
  ["mf-dicom-client/dicom-client-*.zip",
   "mf-server-config/server-config-*.zip",
   "nig-commons/nig-commons.jar",
   "nig_dcmtools/dcmtools-*.zip",
   "nig_essentials/mfpkg-nig_essentials-*.zip",
   "nig_pvupload/pvupload-*.zip",
   "nig_transcode/mfpkg-nig_transcode-*.zip",
   "pssd/mfpkg-pssd-*.zip"]

BUILT_COMPONENTS.each() do | path |
  bash "copy built #{path}" do
    code "cp #{build_tree}/dist/#{path} #{installers}"
    cwd dir
  end
end
