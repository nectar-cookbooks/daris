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

module DarisUrls

  # The 1st level keys represent official releases, apart from 'latest'.  
  # The 2nd level keys mostly represent the available components (of interest).
  # The value arrays consist of the component version, the minimum mediaflux 
  #   version the component notionally depends on, and a flag to say if the
  #   pre-built component is downloadable in this version.
  DARIS_RELEASES = {
    'stable-2-18' => {
      'type' => 'stable',
      'nig_essentials' => ['0.19', '3.8.029'],
      'nig_transcode' => ['0.33', '3.8.029'],
      'pssd' => ['2.04', '3.8.029'],
      'daris_portal' => ['0.29', '3.8.029'],
      'server_config' => ['1.0'],
      'pvupload' => ['0.33'],
      'dicom_client' => ['1.0'],
      'dcmtools' => ['0.29'],
      'nig-commons' => ['0.40']
    },
    'stable-2-19' => {
      'type' => 'stable',
      'nig_essentials' => ['0.20', '3.8.050'],
      'nig_transcode' => ['0.34', '3.8.050'],
      'pssd' => ['2.06', '3.8.050'],
      'daris_portal' => ['0.33', '3.8.050'],
      'server_config' => ['1.0'],
      'pvupload' => ['0.34'],
      'dicom_client' => ['1.0'],
      'dcmtools' => ['0.29'],
      'nig-commons' => ['0.40']
    },
    'stable-2-20' => {
      'type' => 'stable',
      'nig_essentials' => ['0.22', '3.8.057'],
      'nig_transcode' => ['0.35', '3.8.057'],
      'pssd' => ['2.07', '3.8.057'],
      'daris_portal' => ['0.38', '3.8.050'],
      'server_config' => ['1.0'],
      'pvupload' => ['0.34'],
      'dicom_client' => ['1.0'],
      'dcmtools' => ['0.29'],
      'nig-commons' => ['0.41']
    },
    'stable-2-21' => {
      'type' => 'stable',
      'nig_essentials' => ['0.22', '3.9.005'],
      'nig_transcode' => ['0.35', '3.9.005'],
      'pssd' => ['2.15', '3.9.005'],
      'daris_portal' => ['0.44', '3.9.005'],
      'server_config' => ['1.0'],
      'pvupload' => ['0.34'],
      'dicom_client' => ['1.0'],
      'dcmtools' => ['0.29'],
      'nig-commons' => ['0.41', '3.9.005']
    },
    'stable-2-22' => {
      'type' => 'stable',
      'nig_essentials' => ['0.23', '4.0.005'],
      'nig_transcode' => ['0.36', '4.0.005'],
      'pssd' => ['2.18', '4.0.005'],
      'daris_portal' => ['0.46', '4.0.005'],
      'server_config' => ['1.0'],
      'pvupload' => ['0.35'],
      'dicom_client' => ['1.0'],
      'dcmtools' => ['0.29'],
      'nig-commons' => ['0.42', '4.0.004'],
      'sinks' => ['0.07', '4.0.005'],
      'transform' => ['1.3.07', '4.0.005']
    },
    'stable-2-23' => {
      'type' => 'stable',
      'nig_essentials' => ['0.23', '4.0.010'],
      'nig_transcode' => ['0.36', '4.0.010'],
      'pssd' => ['2.18', '4.0.010'],
      'daris_portal' => ['0.47', '4.0.010'],
      'server_config' => ['1.0'],
      'pvupload' => ['0.35'],
      'dicom_client' => ['1.0'],
      'dcmtools' => ['0.29'],
      'nig-commons' => ['0.42', '4.0.010'],
      'sinks' => ['0.07', '4.0.010'],
      'transform' => ['1.3.07', '4.0.010']
    }
  }
  
  DARIS_PATTERNS = {
    'nig_commons' => 'nig-commons%{type}.jar',
    'nig_essentials' => 'mfpkg-nig_essentials-%{ver}-mf%{mver}%{type}.zip',
    'nig_transcode' => 'mfpkg-nig_transcode-%{ver}-mf%{mver}%{type}.zip',
    'pssd' => 'mfpkg-pssd-%{ver}-mf%{mver}%{type}.zip',
    'daris_portal' => 'mfpkg-daris-%{ver}-mf%{mver}%{type}.zip',
    'server_config' => 'server-config-%{ver}%{type}.zip',
    'pvupload' => 'pvupload-%{ver}%{type}.zip',
    'dicom_client' => 'dicom-client-%{ver}%{type}.zip',
    'dcmtools' => 'dcmtools-%{ver}%{type}.zip',
    'sinks' => 'mfpkg-nig_sinks-%{ver}-mf%{mver}%{type}.zip',
    'transform' => 'mfpkg-transform-%{ver}-mf%{mver}%{type}.zip'
  }

  CHECKOUTS = {
    'nig_essentials' => ['nigtk', 'mfp-essentials'],
    'nig_transcode' => ['nigtk', 'mfp-transcode'],
    'pssd' => ['nigtk', 'mfp-pssd'],
    'daris_portal' => ['daris', ''],
    'server_config' => ['nigtk', 'mfc-server-config'],
    'pvupload' => ['nigtk', 'mfc-pvupload'],
    'dicom_client' => ['nigtk', 'mfc-dicom-client'],
    'dcmtools' => ['niktk', 'dcmtools'],
    'nig-commons' => ['nigtk', 'commons'],
    'sinks' => ['nigtk', 'mfp-sinks'],
    'transform' => ['transform', '']
  }

  class JavaProps
    attr :file, :properties

    def initialize(file)
      @file = file
      @properties = {}
      IO.foreach(file) do |line|
        @properties[$1.strip] = $2 if line =~ /([^=]*)=(.*)\/\/(.*)/ || line =~ /([^=]*)=(.*)/
      end
    end
  end

  # Options for 'wget'ing DaRIS downloadables.
  def wgetOpts(node, refresh)
    u = node['daris']['download_user']
    p = node['daris']['download_password']
    opts = "--user=#{u} --password=#{p} " +
      "--no-check-certificate --secure-protocol=SSLv3"
    if refresh then
      opts += " -N"
    end
    return opts
  end

  # Test if we should try to download a component if we don't have
  # suitable local copy.  
  def _tryDownload?(node, item) 
    if node['daris']['use_local_daris_builds'] then
      return false
    elsif node['daris'][item] then
      return true
    else 
      version_info = getRelease(node)[item] || ['1.0', '1.0', false]
      return version_info.length < 3 || version_info[2]
    end
  end

  # Lookup / figure out the URL for a DaRIS component based on 
  # the settings in the Node object.  If the node has specified a
  # file (or url), that is turned into a URL and returned.  Otherwise
  # we lookup the version information for the item in the selected
  # DaRIS release, interpolate the version into a filename, and 
  # then turn that into a URL.  
  def darisUrlAndFile(node, item)
    specified = node['daris'][item]
    if specified then
      url = assemble(node, specified, node['daris']['download_dir'])
      file = Pathname(URI(url).path).basename
    else 
      file, type = _buildDarisFileAndType(node, item)
      url = _assemble(node, file, type)
    end
    if _tryDownload?(node, item) then 
      return url, file
    else
      return nil, file
    end
  end

  def _buildDarisFileAndType(node, item)
    local = node['daris']['release'] == 'local_builds'
    pat = DARIS_PATTERNS[item]
    if ! pat then
      raise "There is no filename pattern for '#{item}'"
    end 
    release = getRelease(node)
    version_info = release[item] || ['1.0', '1.0', false]
    type = release['type'] || 'stable'
    type_suffix = local ? "" : "-#{type}"
    hash = {
      :type => type_suffix, 
      :ver => version_info[0] || '',
      :mver => version_info[1] || ''
    }
    return pat % hash, type
  end

  def getRelease(node)
    relname = node['daris']['release']
    if ! relname then
      raise "No DaRIS release has been specified"
    end
    if relname == 'local_builds' then
      release = _extractReleaseInfoFromCheckout(node)
    else
      release = _scrapeReleaseInfo(node, relname) || DARIS_RELEASES[relname]
      if ! release then
        raise "Release #{relname} is not current, and there is no "
              "entry for it in 'releases'"
      end
    end
    return release
  end

  def getRequiredMediafluxVersion(node) 
    release = getRelease(node)
    version = nil
    release.each() do |key, value|
      if value.kind_of?(Array) then
        if value.length >= 2 then
          v = value[1]
          if version == nil || 
              Chef::VersionConstraint.new("> #{version}").include?(v) then
            version = v
          end
        end
      end
    end
    raise "Cannot determine the required Mediaflux version" unless version
    return version
  end

  def _scrapeReleaseInfo(node, relname)
    auth = [node['daris']['download_user'], node['daris']['download_password']]
    download_url = node['daris']['download_url']
    # (This is to prevent a redirect that messes up OpenURI's handling
    #  of the authentication.)
    download_url += "/" unless download_url.end_with?("/")
    if relname != 'latest' then
      # Check that the current 'stable' build is the one we want.
      stable = nil
      OpenURI.open_uri(download_url, 
                       http_basic_authentication: auth,
                       ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE) do |f|
        if f.status[0] != '200' then
          raise "Unable to fetch page #{page_url}: status = #{f.status}"
        end
        f.each do |line|
          m = /Stable Builds \(([^)]+)\)/.match(line)
          if m then
            raise "Found multiple 'Stable Builds' lines" if stable
            stable = m[1]
          end
        end
        raise "Found no multiple 'Stable Builds' lines" unless stable
      end
      if stable != relname then
        return nil
      end
    end
    type = relname == 'latest' ? 'latest' : 'stable'
    regexes = {
      'nig_essentials' => "#{type}/mfpkg-nig_essentials",
      'nig_transcode' => "#{type}/mfpkg-nig_transcode",
      'pssd' => "#{type}/mfpkg-pssd",
      'daris_portal' => "#{type}/mfpkg-daris",
      'server_config' => "#{type}/server-config",
      'pvupload' => "#{type}/pvupload",
      'dicom_client' => "#{type}/dicom-client",
      'dcmtools' => "#{type}/dcmtools",
      'nig-commons' => "#{type}/nig-commons",
      'sinks' => "#{type}/mfpkg-nig_sinks",
      'transform' => "#{type}/mfpkg-transform"
    }
    urls = scrapeUrls(regexes, download_url, 
                      http_basic_authentication: auth,
                      ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE)
    release = { 'type' => type, 'name' => relname }
    urls.each do |key, url|
      file = /[^\/]+$/.match(url)[0]
      m = /.+-([0-9.]+)-mf([0-9.]+)-.*/.match(file)
      if m then
        release[key] = [m[1], m[2]]
      else
        m = /.+-([0-9.]+)-.*/.match(file)
        if m then 
          release[key] = [m[1]]
        else
          release[key] = [] # no version number; e.g. nig-commons
        end
      end
    end
    return release
  end
  
  def _extractReleaseInfoFromCheckout(node)
    checkout_dir = "#{node['daris']['build_tree']}/git"
    if ! File.exists?(checkout_dir) then
      raise "Can't find the checkout directory #{checkout_dir}"
    end
    release = _scrapeReleaseInfo(mode, 'latest')
    CHECKOUTS.each() do |pkg, details|
      checkout = "#{checkout_dir}/#{details[0]}"
      if File.exists?(checkout) then
        props_file = "#{checkout}/#{details[1]}/build.properties"
        if ! File.exists?(props_file) then
          raise "Can't find build properties for #{pkg} in #{checkout}"
        end
        props = JavaProps.new(props_file)
        app_version = props.properties['app.version']
        mf_version = props.properties['mf.server.version']
        if ! app_version then
          raise "Can't find an 'app.version' property for #{pkg}"
        end
        if ! mf_version && release[pkg][1] then
          raise "Can't find an 'mf.server.version' property for #{pkg}"
        end
        release[pkg] = mf_version ? [app_version, mf_version] : [app_version]
        Chef::Log.debug("Build info for #{pkg} is #{release[pkg]}")
      end
    end
    return release;
  end

  # If a release is not stable, we cannot assume that a cached local copy
  # is current just based on the name.
  def unstableRelease?(node)
    return getRelease(node)['type'] != 'stable'
  end
  
  def _assemble(node, file, dir)
    if /^[a-zA-Z]+:.+$/.match(file) then
      return file
    else
      base = node['daris']['download_url']
      if ! file.start_with?('/') && dir then
        if ! base.end_with?('/') && ! dir.start_with?('/') then
          base += '/'
        end
        base += dir
      end
      if ! base.end_with?('/') && ! file.start_with?('/') then
        base += '/'
      end
      return base + file
    end
  end
  
end 
