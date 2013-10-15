#!/bin/sh
#
# The server-config command interactively (re-)configures some common 
# Mediaflux / DaRIS server settings.
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

JAR=`dirname $0`/server-config.jar
if [ ! -f "${JAR}" ]; then
    echo "Error: could not find file server-config.jar." >&2
    exit 1
fi

# Uncomment the following to enable general tracing.
# MF_VERBOSE=-verbose

$JAVA -Dmf.host=$MFLUX_HOST -Dmf.port=$MFLUX_PORT \
    -Dmf.transport=$MFLUX_TRANSPORT -jar $JAR

RETVAL=$?
exit $RETVAL
