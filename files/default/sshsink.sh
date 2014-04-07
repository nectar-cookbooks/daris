#!/bin/sh

. /etc/mediaflux/servicerc
if [ $? -ne 0 ]; then
    exit 1
fi

MFCOMMAND=${MFLUX_BIN}/mfcommand

#
# Utility for configuring DaRIS SSH sinks.
#

addsink() {
    SCRIPT=/tmp/sshsink_$$
    cat > $SCRIPT <<EOF
        sink.add :name $1 \
	    :destination < \
                :type scp :arg -name host $2 \
	        :arg -name port 22 \
                :arg -name hostkey [xvalue host-key [ssh.host.key.scan \
                                                     :host $2 :type rsa]] \
                :arg -name decompress true \
            >  
EOF
    $MFCOMMAND logon $MFLUX_DOMAIN $MFLUX_USER $MFLUX_PASSWORD
    $MFCOMMAND source $SCRIPT
    RC=$?
    $MFCOMMAND logoff
    rm $SCRIPT
}

removesink() {
    $MFCOMMAND logon $MFLUX_DOMAIN $MFLUX_USER $MFLUX_PASSWORD
    $MFCOMMAND sink.remove :name $1
    RC=$?
    $MFCOMMAND logoff
}

listsinks() {
    $MFCOMMAND logon $MFLUX_DOMAIN $MFLUX_USER $MFLUX_PASSWORD
    $MFCOMMAND sink.list
    RC=$?
    $MFCOMMAND logoff
}

describesink() {
    $MFCOMMAND logon $MFLUX_DOMAIN $MFLUX_USER $MFLUX_PASSWORD
    $MFCOMMAND sink.describe :name $1
    RC=$?
    $MFCOMMAND logoff
}

help() {
    echo "not implemented yet"
    exit 1
}

case $1 in
  add)
    shift
    addsink "$@"
    ;;
  remove)
    shift
    removesink "$@"
    ;;
  list)
    shift
    listsinks "$@"
    ;;
  describe)
    shift
    describesink "$@"
    ;;
  help)
    shift
    help "$@"
    ;;
  *)
    echo "Unknown subcommand '$1' - run '$0 help' for help"
    exit 1
    ;;
esac
exit $RC
