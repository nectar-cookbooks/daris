#!/bin/sh

if [ -r /etc/mediaflux/mfluxrc ] ; then
    . /etc/mediaflux/mfluxrc
fi
if [ -r /etc/mediaflux/mfuploadrc ] ; then
    . /etc/mediaflux/mfuploadrc
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

if [ -z "$MFLUX_HOST" -o -z "$MFLUX_PORT" -o -z "$MFLUX_TRANSPORT" ] ; then
    echo "Error: the following environment variables must be set; e.g. in an 'rc' file"
    echo "    MFLUX_HOST, MFLUX_PORT, MFLUX_TRANSPORT"
    exit 1
fi

# Do it
$JAVA -Dmf.host=$MFLUX_HOST -Dmf.port=$MFLUX_PORT -Dmf.transport=$MFLUX_TRANSPORT  -cp $JAR  nig.mf.pssd.client.dicom.DicomMF "$@"

RETVAL=$?
exit $RETVAL
