::Chef::Recipe.send(:include, DarisUrls)
::Chef::Recipe.send(:include, ScrapeUrl)

release = scrapeRelease(node)
puts "release is #{release}"
