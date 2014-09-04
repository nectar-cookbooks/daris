::Chef::Recipe.send(:include, DarisUrls)
::Chef::Recipe.send(:include, ScrapeUrl)

release = scrapeDaRISRelease(node)
puts "release is #{release}"
