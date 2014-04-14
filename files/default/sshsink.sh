#!/bin/sh
#
# Admin command for configuring Mediaflux / DaRIS sinks.

. /etc/mediaflux/servicerc
if [ $? -ne 0 ]; then
    exit 1
fi

MFCOMMAND=${MFLUX_BIN}/mfcommand
RC=0

addsink() {
    NAME=$1
    TYPE=scp
    PORT=22
    DESC=
    DECOMP=true
    FILEMODE=600]
    shift
    while [ $# -gt 0 ] ; do
	case $1 in
	    --host)
		HOST="$2"
		shift 2
		;;
	    --port)
		PORT="$2"
		shift 2
		;;
	    --desc*)
		DESC="$2"
		shift 2
		;;
	    --decomp*)
		DECOMP=true
		shift
		;;
	    --nodecomp*)
		DECOMP=false
		shift
		;;
	    --hostkey)
		HOSTKEY="$2"
		shift 2
		;;
	    --filemode)
		FILEMODE="$2"
		shift 2
		;;
	    --user)
		USER="$2"
		shift 2
		;;
	    --password)
		PASSWORD="$2"
		shift 2
		;;
	    --pkfile)
	        PKFILE="$2"
		shift 2
		;;
	    --*)
		echo "unknown option $1"
		RC=1
		exit
		;;
	    
	esac
    done
    SCRIPT=/tmp/sshsink_$$
    cat > $SCRIPT <<EOF
        sink.add :name "$NAME" \
	    :destination < \
                :type "$TYPE" :arg -name host "$HOST" \
	        :arg -name port "$PORT" \
                :arg -name hostkey [xvalue host-key [ssh.host.key.scan \
                                                     :host "$HOST" :type rsa]] \
                :arg -name decompress "$DECOMP" \
            > \
            :description "$DESC"
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
    echo "Usage: $1 subcommand [<args>]"
    echo "where the subcommands are:"
    echo "  add <sinkname> --host <hostname> [ --port <port> ]"
    echo "               [ --description <description> ]" 
    echo "               [ --decompress | --nodecompress ]" 
    echo "                      - adds an SSH/SCP sink"
    echo "  describe <sinkname> - describes a sink"
    echo "  list                - lists all registered sink names"
    echo "  remove <sinkname>   - removes a sink"
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
    CMD=$0
    help "$0"
    ;;
  *)
    echo "Unknown subcommand '$1' - run '$0 help' for help"
    exit 1
    ;;
esac
exit $RC
