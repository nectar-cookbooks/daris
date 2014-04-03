#!/bin/sh

. /etc/mediaflux/servicerc
if [ $? -ne 0 ]; then
    exit 1
fi

#
# Utility for configuring DaRIS SSH sinks.
#

addsink() {
    echo "not implemented yet"
    exit 1
}

removesink() {
    echo "not implemented yet"
    exit 1
}

listsinks() {
    $MFCOMMAND logon $MFLUX_DOMAIN $MFLUX_USER $MFLUX_PASSWORD
    $MFCOMMAND sink.list
    $MFCOMMAND logoff
    exit 1
}

help() {
    echo "not implemented yet"
    exit 1
}

case $1 in
  add)
    shift
    addsink
    ;;
  remove)
    shift
    removesink
    ;;
  list)
    listsinks
    ;;
  help)
    help
    ;;
  *)
    echo "Unknown subcommand '$1' - run '$0 help' for help"
    exit 1
    ;;
esac
