module DarisUrls
  releases = {
    'stable-2-18' => {
      'type' => 'stable',
      'nig_essentials' => ['0.19', '3.8.029'],
      'nig_transcoder' => ['0.33', '3.8.029'],
      'pssd' => ['2.04', '3.8.029'],
      'daris_portal' => ['0.29', '3.8.029'],
      'server_config' => ['1.0'],
      'pvupload' => ['0.33'],
      'dicom-client' => ['1.0'],
      'dcmtools' => ['0.29'],
    },
    'latest' => {
      'type' => 'latest',
      'nig_essentials' => ['0.20', '3.8.029'],
      'nig_transcoder' => ['0.33', '3.8.029'],
      'pssd' => ['2.06', '3.8.040'],
      'daris_portal' => ['0.32', '3.8.040'],
      'server_config' => ['1.0'],
      'pvupload' => ['0.33'],
      'dicom-client' => ['1.0'],
      'dcmtools' => ['0.29']
    }
  }
  
  patterns = {
    'nig_commons' => 'nig-commons-%{type}.jar',
    'nig_essentials' => 'mfpkg-nig_essentials-%{ver}-mf%{mver}-%{type}.zip',
    'nig_transcoder' => 'mfpkg-nig_transcoder-%{ver}-mf%{mver}-%{type}.zip',
    'pssd' => 'mfpkg-pssd-%{ver}-mf%{mver}-%{type}.zip',
    'daris_portal' => 'mfpkg-daris-%{ver}-mf%{mver}-%{type}.zip',
    'server_config' => 'server-config-%{ver}-%{type}.zip',
    'pvupload' => 'pvupload-%{ver}-%{type}.zip',
    'dicom-client' => 'dicom-client-%{ver}-%{type}.zip',
    'dcmtools' => 'dcmtools-%{ver}-%{type}.zip'
  }
  
  # Get the filename part of a URL string
  def getFile(url_string)
    return Pathname(URI(url_string).path).basename
  end

  # Lookup / figure out the URL for a DaRIS downloadable based on 
  # the settings in the Node object.  If the node has specified a
  # file (or url), that is turned into a URL and returned.  Otherwise
  # we lookup the version information for the item in the selected
  # DaRIS release, interpolate the versions into a filename, and 
  # then turn that into a URL.
  def getUrl(node, item)
    specified = node['daris'][item]
    if specified then
      return assemble(node, specified)
    end
    pat = DarisUrls::patterns[item]
    if ! pat then
      raise "There is no filename pattern for '#{item}'"
    end 
    release_name = node['daris']['release']
    if ! release_name then
      raise "No DaRIS release has been specified"
    end 
    release = releases[release_name]
    if ! release then
      raise "There is no 'releases' entry for release '#{release_name}'"
    end
    versions = release[item] || ['1.0']
    hash = {
      'type' => release['type'] || 'stable',
      'ver' => versions[0],
      'mver' => versions[1] || ''
    }
    file = pat % hash
    return assemble(node, file)
  end

  def assemble(node, file)
      if /^[a-zA-Z]+:.+$/.match(file) then
        return file
      else
        base = node['daris']['download_url']
        dir = node['daris']['download_dir']
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
