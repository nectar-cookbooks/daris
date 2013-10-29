#!/bin/sh
#
# This wrapper calls the Bruker upload Java client. This scripts sets a
# number of parameters which can be changed by editing.  Anything that is
# an argument to the Jar but not supplied directly by this script can 
# also be passed in.   The syntax is
# mfpvload.sh <options> <source directory>
#
# For example:
# mfpvload.sh -id 81.2 <source directory>
#
# specifies a CID of 81.2
#

if [ -r /etc/mediaflux/mfluxrc ] ; then
    . /etc/mediaflux/mfluxrc
fi
if [ -r $HOME/.mfluxrc ] ; then
    . $HOME/.mfluxrc
fi

JAVA=`which java`
if [ -z "${JAVA}" ]; then
        echo "Error: could not find java." >&2
        exit 1
fi

JAR=`dirname $0`/pvupload.jar
if [ ! -f "${JAR}" ]; then
        echo "Error: could not find file pvupload.jar." >&2
        exit 1
fi

# The amount of time to wait to see if a corresponding DICOM series
# appears in the server. Specified in seconds.
MF_WAIT=60

# Uncomment the following to enable general tracing.
# MF_VERBOSE=-verbose

# Auto create subjects from CID
# Comment out to disable
AUTO_SUBJECT_CREATE=-auto-subject-create

# Parse NIG-specific meta-data and locate on Subject
# Comment out to disable
NIG_META=-nig-subject-meta-add

# Do the upload
$JAVA -Dmf.host=$MFLUX_HOST -Dmf.port=$MFLUX_PORT \
    -Dmf.transport=$MFLUX_TRANSPORT -Dmf.domain=$MFLUX_DOMAIN \
    -Dmf.user=$MFLUX_USER -Dmf.password=$MFLUX_PASSWORD \
    -jar $JAR -wait $MF_WAIT $MF_VERBOSE $NIG_META $AUTO_SUBJECT_CREATE $@

RETVAL=$?
exit $RETVAL
