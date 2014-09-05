name "daris"
maintainer "Stephen Crawley"
maintainer_email "s.crawley at uq dot edu dot au"
license "BSD"
description "Install and configures a DaRIS instance"
long_description "Installs and configures a MediaFlux + DaRIS instance.  "
                 "Before you start, it is necessary to obtain access to the "
                 "MediaFlux installation media, and a MediaFlux license key."
version "0.9.5"

depends "java", ">= 1.13.0"
depends "mediaflux", ">= 0.9.16"
depends "pvconv"
depends "minc-toolkit"
depends "setup", ">= 1.3"
