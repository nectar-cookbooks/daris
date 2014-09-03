Change Log for the Daris cookbook
=================================

Version 0.9.4
-------------
 - Implemented checking of the installed Mediaflux version
 - Updates to sink (and transform) authorization script
 - Other fixes

Version 0.9.3
-------------
 - Added command for configuring sink access into a remote machine.

Version 0.9.2
-------------
 - Local builds now require the release name 'local_builds'
 - In local build mode, we now interogate the respective 'build.properties'
   files to find package and MF version numbers
 - Optionally load the 'sinks' and 'transforms' packages.  (Note: transforms
   are currently only available via local builds.)
 - Implemented shell scripts for configuring Kepler workflows and sinks.

Version 0.9.1
-------------
 - Support for local builds for the DaRIS software (#6 & #7)

Version 0.9.0
-------------
 - First properly numbered version
 - Add stores to the list for mediaflux backups

