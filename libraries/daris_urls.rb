module DarisUrls
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
    'latest' => {
      'type' => 'latest',
      'nig_essentials' => ['0.21', '3.8.050'],
      'nig_transcode' => ['0.35', '3.8.050'],
      'pssd' => ['2.07', '3.8.050'],
      'daris_portal' => ['0.35', '3.8.050'],
      'server_config' => ['1.0'],
      'pvupload' => ['0.34'],
      'dicom_client' => ['1.0'],
      'dcmtools' => ['0.29'],
      'nig-commons' => ['0.41']
    }
  }
  
  DARIS_PATTERNS = {
    'nig_commons' => 'nig-commons-%{type}.jar',
    'nig_essentials' => 'mfpkg-nig_essentials-%{ver}-mf%{mver}-%{type}.zip',
    'nig_transcode' => 'mfpkg-nig_transcode-%{ver}-mf%{mver}-%{type}.zip',
    'pssd' => 'mfpkg-pssd-%{ver}-mf%{mver}-%{type}.zip',
    'daris_portal' => 'mfpkg-daris-%{ver}-mf%{mver}-%{type}.zip',
    'server_config' => 'server-config-%{ver}-%{type}.zip',
    'pvupload' => 'pvupload-%{ver}-%{type}.zip',
    'dicom_client' => 'dicom-client-%{ver}-%{type}.zip',
    'dcmtools' => 'dcmtools-%{ver}-%{type}.zip'
  }

  # Options for 'wget'ing DaRIS downloadables.
  def wgetOpts(node, refresh)
    u = node['daris']['download_user']
    p = node['daris']['download_password']
    opts "--user=#{u} --password=#{p} " +
      "--no-check-certificate --secure-protocol=SSLv3"
    if refresh then
      opts += " -N"
    end
    return opts
  end

  # Get the filename part of a URL string
  def darisUrlToFile(url_string)
    return Pathname(URI(url_string).path).basename
  end

  # Lookup / figure out the URL for a DaRIS downloadable based on 
  # the settings in the Node object.  If the node has specified a
  # file (or url), that is turned into a URL and returned.  Otherwise
  # we lookup the version information for the item in the selected
  # DaRIS release, interpolate the versions into a filename, and 
  # then turn that into a URL.
  def buildDarisUrl(node, item)
    specified = node['daris'][item]
    if specified then
      return assemble(node, specified, node['daris']['download_dir'])
    end
    pat = DARIS_PATTERNS[item]
    if ! pat then
      raise "There is no filename pattern for '#{item}'"
    end 
    release = getRelease(node)
    versions = release[item] || ['1.0']
    type = release['type'] || 'stable'
    hash = {
      :type => type, 
      :ver => versions[0] || '',
      :mver => versions[1] || ''
    }
    file = pat % hash
    return assemble(node, file, type)
  end

  def getRelease(node)
    release_name = node['daris']['release']
    if ! release_name then
      raise "No DaRIS release has been specified"
    end 
    release = DARIS_RELEASES[release_name]
    if ! release then
      raise "There is no 'releases' entry for release '#{release_name}'"
    end
    return release
  end

  # If a release is not stable, we cannot assume that a cached local copy
  # is current just based on the name.
  def unstableRelease?(node)
    return getRelease(node)['type'] != 'stable'
  end
  
  def assemble(node, file, dir)
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
