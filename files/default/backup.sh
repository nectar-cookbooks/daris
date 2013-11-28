#!/bin/sh
#
# Perform a DaRIS backup.
#

if [ -e /etc/mediaflux/servicerc ] ; then
    . /etc/mediaflux/servicerc
fi

DIR=/tmp/backup

mkdir -p $DIR

MF_COMMAND="$MFLUX_BIN/mfcommand"
$MF_COMMAND logon $MFLUX_DOMAIN $MFLUX_USER "$MFLUX_PASSWORD"
$MF_COMMAND source -dir=$DIR $MFLUX_HOME/config/daris_backup.tcl
RC=$?
$MF_COMMAND logoff

exit $?
