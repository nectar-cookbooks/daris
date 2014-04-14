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
    NOHOSTKEY=0
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
	    --nohostkey)
		NOHOSTKEY=1
		shift
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

    ARGS=
    if [ ! -z "$USER" ] ; then
	ARGS="$ARGS :arg -name user \"$USER\""
    fi
    if [ ! -z "$PASSWORD" ] ; then
	ARGS="$ARGS :arg -name password \"$PASSWORD\""
    fi
    if [ -z "$HOSTKEY" -a $NOHOSTKEY -eq 0 ] ; then
	HOSTKEY=`ssh-keyscan -t rsa $HOST | grep -v \# | cut -f 3`
    fi
    if [ ! -z "$HOSTKEY" ] ; then
	ARGS="$ARGS :arg -name hostkey \"$HOSTKEY\""
    fi
    if [ ! -z "$FILEMODE" ] ; then
	ARGS="$ARGS :arg -name filemode \"$FILEMODE\""
    fi
    if [ ! -z "$PKFILE" ] ; then
        KEY=`cat $PKFILE`
	ARGS="$ARGS :arg -name prvkey \"$KEY\""
    fi

    SCRIPT=/tmp/sshsink_$$
    cat > $SCRIPT <<EOF
        sink.add :name "$NAME" \
	    :destination < \
                :type "$TYPE" :arg -name host "$HOST" \
	        :arg -name port "$PORT" \
                :arg -name decompress "$DECOMP" \
                $ARGS \
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
