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
    TYPE=$2
    DESC=
    shift 2
    case $TYPE in
        scp)
            scp "$@"
            ;;
        owncloud)
            owncloud "$@"
            ;;
        webdav)
            webdav "$@"
            ;;
        filesystem)
            filesystem "$@"
            ;;
        *)
            echo "Unknown sink type $TYPE"
    esac
    $MFCOMMAND logon $MFLUX_DOMAIN $MFLUX_USER $MFLUX_PASSWORD
    $MFCOMMAND source $SCRIPT
    RC=$?
    $MFCOMMAND logoff
    rm $SCRIPT
}

owncloud() {
    URL=
    CHUNKED=true
    DECOMP=false
    while [ $# -gt 0 ] ; do
	case $1 in
	    --url)
		URL="$2"
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
	    --unchunked)
		CHUNKED=false
		shift
		;;
	    --*)
		echo "unknown option $1"
		RC=1
		exit
		;;
	esac
    done

    if [ -z "$URL" ] ; then
	echo "No --url specified"
	RC=1
	exit
    fi

    SCRIPT=/tmp/owncloudsink_$$
    if [ -z "$HOST" ] ; then
	cat > $SCRIPT <<EOF
            sink.add :name "$NAME" \
	        :destination < \
                    :type "$TYPE" :arg -name url $URL" \
                    :arg -name chunked "$CHUNKED" \
                    :arg -name decompress "$DECOMP" \
                > \
            :description "$DESC"
EOF
	exit
    fi
}

scp() {
    PORT=22
    DECOMP=false
    NOHOSTKEY=0
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
            --basedir)
		BASEDIR="$2"
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
    if [ -z "$HOST" ] ; then
	cat > $SCRIPT <<EOF
            sink.add :name "$NAME" \
	        :destination < \
                    :type "$TYPE" :arg -name port "$PORT" \
                    :arg -name decompress "$DECOMP" \
                > \
            :description "$DESC"
EOF
	exit
    fi

    ARGS=
    if [ ! -z "$USER" ] ; then
	ARGS="$ARGS :arg -name user \"$USER\""
    fi
    if [ ! -z "$PASSWORD" ] ; then
	ARGS="$ARGS :arg -name password \"$PASSWORD\""
    fi
    if [ -z "$HOSTKEY" -a $NOHOSTKEY -eq 0 ] ; then
	HOSTKEY=`ssh-keyscan -t rsa $HOST 2>/dev/null | awk '{print $3}'`
    fi
    if [ ! -z "$HOSTKEY" ] ; then
	ARGS="$ARGS :arg -name hostkey \"$HOSTKEY\""
    fi
    if [ ! -z "$FILEMODE" ] ; then
 	ARGS="$ARGS :arg -name filemode \"$FILEMODE\""
    fi
    if [ ! -z "$BASEDIR" ] ; then
 	ARGS="$ARGS :arg -name basedir \"$BASEDIR\""
    fi
    if [ ! -z "$PKFILE" ] ; then
        KEY=`cat $PKFILE`
 	ARGS="$ARGS :arg -name prvkey \"$KEY\""
    fi

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
    if [ $# -eq 0 ]; then
	echo "The $0 command allows you to manage DaRIS / Mediaflux sinks" 
	echo "  from the command line.  Most operations require Mediaflux"
	echo "  administrator privilege."
        echo 
	echo "Usage: $0 subcommand [<args>]"
	echo "where the subcommands are:"
	echo "    add <sinkname> <type> --desc <description> ..."
        echo "                             - defines a sink"
	echo "    describe <sinkname>      - describes a sink"
	echo "    help [ <subcommand> ...] - outputs command help"
	echo "    list                     - lists registered sinks"
	echo "    remove <sinkname>        - removes a sink"
    else
	case $1 in
	    add)
		shift
		helpadd "$@"
		;;
	    help)
		echo "$0 help                  - outputs command help"
		echo "$0 help <subcommand> ... - outputs help for a subcommand"
		;;
	    describe)
		echo "$0 describe <sinkname> - describes a sink"
		;;
	    list)
		echo "$0 list - lists registered sinks"
		;;
	    remove)
		echo "$0 remove <sinkname> - removes a sink"
		;;
	    *)
		echo "Unknown subcommand '$1'"
		help
		;;
	esac
    fi
    RC=1
}

helpadd() {
    if [ $# -eq 0 ]; then
	echo "$0 add <sinkname> <type> ..."
	echo "   where <sinkname> is a sink name and <type> is the sink type"
        echo "Adds a sink descriptor to Mediaflux.  The supported sink types"
        echo "are scp, webdav, owncloud or filesystem.  For the options for"
        echo "each sink type, run '$0 help add <type>'"
    else
	case $1 in
	    scp)
		helpaddscp
		;;
	    webdav)
		helpaddwebdav
		;;
	    owncloud)
		helpaddowncloud
		;;
	    filesystem)
		helpaddfilesystem
		;;
	    *)
		echo "Unknown sink type $1"
		echo "Valid types are scp, webdav, owncloud or filesystem"
		;;
	esac
    fi
}

helpaddscp() {
    echo "$0 add <sinkname> scp [ --host <host> ]" 
    echo "    [ --port <port> ] [ --hostkey <hostkey> ] [ --nohostkey ]"
    echo "    [ --user <user> ( --password <password> | --pkfile <file> ) ]"
    echo "    [ --decomp ] [ --filemode <mode> ] [ --basedir <path> ]" 
    echo "    [ --desc '<description string>' ]" 
    echo "This command adds an SSH/SCP sink.  The sink can be generic, or"
    echo "you can provide a specific host, authorization and other details."
    echo "RSA and IPv4 are assumed by this script, and the default port is"
    echo "the standard SSH port.  Many options are ignored for generic sinks."
    echo ""
    echo "Host identification: The --host can be sepecified either as a DNS"
    echo "name or as an IPv4 address.  The --hostkey (if provided) is used"
    echo "for definitive SSH host identification (to guard against spoofing"
    echo "or man-in-the-middle attacks).  If neither --hostkey or --nohostkey"
    echo "is given, ssh-scankeys is run to find the RSA hostkey for the host."
    echo "If you set --nohostkey, the sink will not verify the identity of"
    echo "the remote host when the user does a transfer."
    echo ""
    echo "Authorization: If --user is given, --password or --pkfile is required"
    echo "also.  NOTE: putting user credentials into a sink definition is"
    echo "insecure because they are visible to anyone with Mediaflux admin"
    echo "privilege, or system-level 'root' privilege."
    echo ""
    echo "Other options: if --basedir is provided, it is the default base"
    echo "directory for the host.  Otherwise, the default base location is the"
    echo "the (remote) user's (remote) home directory.  The --filemode is the"
    echo "the default UNIX/Linux file mode for copied files: default 0660.  The"
    echo "--decomp option enables automatic decompression of the asset by the"
    echo "sink.  This is disabled by default.  If enabled, the user's data is"
    echo "decompressed on the server, and transferred in uncompressed form."
}

helpaddowncloud() {
    echo "$0 add <sinkname> owncloud --url <url>" 
    echo "    [ --decomp ] [ --unchunked ] [ --desc '<description string>' ]" 
    echo "This command adds an owncloud sink.  The <url> is mandatory and"
    echo "should be the WebDAV base URL for the service.  It is recommended"
    echo "that you use an HTTPS URL rather than HTTP."
    echo ""
    echo "Other options: The --decomp option enables automatic decompression "
    echo "of the asset by the sink.  This is disabled by default.  If enabled,"
    echo "the user's data is decompressed on the server, and transferred in"
    echo "uncompressed form.  The --unchunked option disables chunking."
}


if [ $# -eq 0 ] ; then
    help
    exit 1
;;

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
    help "$@"
    ;;
  -*)
    help
    exit 1
    ;;
  *)
    echo "Unknown subcommand '$1' - run '$0 help' for help"
    exit 1
    ;;
esac
exit $RC
