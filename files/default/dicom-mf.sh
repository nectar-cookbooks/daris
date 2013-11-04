#!/bin/sh

if [ -r /etc/mediaflux/mfluxrc ] ; then
    . /etc/mediaflux/mfluxrc
fi
if [ -r $HOME/.mfluxrc ] ; then
    . $HOME/.mfluxrc
fi

if [ -z "$MFLUX_JAVA" ] ; then
    JAVA=`which java`
else
    JAVA="$MFLUX_JAVA"
fi

JAR=`dirname $0`/dicom-client.jar
if [[ ! -f "${JAR}" ]]; then
        echo "Error: could not find file dicom-client.jar." >&2
        exit 1
fi

# Do it
$JAVA -Dmf.host=$MFLUX_HOST -Dmf.port=$MFLUX_PORT -Dmf.transport=$MFLUX_TRANSPORT  -cp $JAR  nig.mf.pssd.client.dicom.DicomMF "$@"

RETVAL=$?
exit $RETVAL
