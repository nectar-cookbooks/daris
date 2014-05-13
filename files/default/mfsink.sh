#!/bin/sh
#
# Admin command for configuring Mediaflux / DaRIS sinks.

. /etc/mediaflux/servicerc
if [ $? -ne 0 ]; then
    exit 1
fi

MFCOMMAND=${MFLUX_BIN}/mfcommand
CMD=`basename $0`
RC=0

expect() {
    EXPECTED=$1
    KEYWORD=$2
    shift 2
    if [ $# -lt $EXPECTED ] ; then
        if [ $EXPECTED -eq 1 ] ; then
	    echo "Syntax error: expected a value after '$KEYWORD'"
	else
	    echo "Syntax error: expected $EXPECTED values after '$KEYWORD'"
	fi
	exit 1
    fi
}

addsink() {
    if [ $# -lt 2 ] ; then
	echo "Syntax error: expected <sinkname> <type>"
	exit 1
    fi
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
            exit 1
            ;;
    esac
    $MFCOMMAND logon $MFLUX_DOMAIN $MFLUX_USER $MFLUX_PASSWORD
    $MFCOMMAND source $SCRIPT
    RC=$?
    $MFCOMMAND logoff
    rm $SCRIPT
}

filesystem() {
    DIRECTORY=
    SPATH=
    SAVE=
    DECOMP=
    while [ $# -gt 0 ] ; do
	case $1 in
	    --directory)
		expect 1 "$@"
		DIRECTORY="$2"
		shift 2
		;;
	    --path)
		expect 1 "$@"
		SPATH="$2"
		shift 2
		;;
	    --desc*)
		expect 1 "$@"
		DESC="$2"
		shift 2
		;;
	    --decomp*)
		expect 1 "$@"
		DECOMP=$2
		shift 2
		;;
	    --save)
		expect 1 "$@"
		SAVE=$2
		shift 2
		;;
	    --*)
		echo "Unknown option $1"
		exit 1
		;;
	esac
    done

    if [ -z "$DIRECTORY" ] ; then
	echo "No --directory specified"
	exit 1
    fi

    if [ -z "$SPATH" -a -z "$DECOMP" ] ; then
	echo "A --path must be specified when not decompressing"
	exit 1
    fi
    ARGS=
    if [ ! -z "$SPATH" ] ; then
	ARGS=":arg name path \"$SPATH\""
    fi
    if [ ! -z "$SAVE" ] ; then
	ARGS="$ARGS :arg name save $SAVE"
    fi
    if [ ! -z "$DECOMP" ] ; then
	ARGS="$ARGS :arg name decompress $DECOMP"
    fi

    if [ -z "$DESC" ] ; then
        DESC_ARG=
    else
        DESC_ARG=":description \"$DESC\""
    fi

    SCRIPT=/tmp/filesystemsink_$$
    cat > $SCRIPT <<EOF
            sink.add :name "$NAME" \
	        :destination < \
                    :type "$TYPE" :arg -name directory "$DIRECTORY" \
                    $ARGS
                > \
            $DESC_ARG
EOF
}

owncloud() {
    URL=
    BASEDIR=
    RUSER=
    RPASSWORD=
    CHUNKED=
    DECOMP=
    while [ $# -gt 0 ] ; do
	case $1 in
	    --url)
		expect 1 "$@"
		URL="$2"
		shift 2
		;;
	    --user)
		expect 1 "$@"
		RUSER="$2"
		shift 2
		;;
	    --password)
		expect 1 "$@"
		RPASSWORD="$2"
		shift 2
		;;
	    --password-key)
		expect 1 "$@"
		RPASSWORD=swkey:$2
		shift 2
		;;
	    --basedir)
		expect 1 "$@"
		BASEDIR="$2"
		shift 2
		;;
	    --desc*)
		expect 1 "$@"
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
	    --chunked)
		CHUNKED=true
		shift
		;;
	    --unchunked)
		CHUNKED=false
		shift
		;;
	    --*)
		echo "unknown option $1"
		exit 1
		;;
	esac
    done

    if [ -z "$URL" ] ; then
	echo "Error: no --url specified"
	exit 1
    fi

    ARGS=
    if [ ! -z "$RUSER" ] ; then
	ARGS=":arg name user \"$RUSER\""
    fi
    if [ ! -z "$RPASSWORD" ] ; then
	ARGS="$ARGS :arg name password \"$RPASSWORD\""
    fi
    if [ ! -z "$BASEDIR" ] ; then
	ARGS="$ARGS :arg name basedir \"$BASEDIR\""
    fi
    if [ ! -z "$DECOMP" ] ; then
	ARGS="$ARGS :arg name decompress $DECOMP"
    fi
    if [ ! -z "$CHUNKED" ] ; then
	ARGS="$ARGS :arg name chunked $CHUNKED"
    fi

    if [ -z "$DESC" ] ; then
        DESC_ARG=
    else
        DESC_ARG=":description \"$DESC\""
    fi


    SCRIPT=/tmp/owncloudsink_$$
    cat > $SCRIPT <<EOF
            sink.add :name "$NAME" \
	        :destination < \
                    :type "$TYPE" :arg -name url "$URL" \
                    $ARGS
                > \
            $DESC_ARG
EOF
}

webdav() {
    URL=
    BASEDIR=
    RUSER=
    RPASSWORD=
    DECOMP=
    while [ $# -gt 0 ] ; do
	case $1 in
	    --url)
		expect 1 "$@"
		URL="$2"
		shift 2
		;;
	    --user)
		expect 1 "$@"
		RUSER="$2"
		shift 2
		;;
	    --password)
		expect 1 "$@"
		RPASSWORD="$2"
		shift 2
		;;
	    --password-key)
		expect 1 "$@"
		RPASSWORD=swkey:$2
		shift 2
		;;
	    --basedir)
		expect 1 "$@"
		BASEDIR="$2"
		shift 2
		;;
	    --desc*)
		expect 1 "$@"
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
	    --*)
		echo "unknown option $1"
		exit 1
		;;
	esac
    done

    if [ -z "$URL" ] ; then
	echo "No --url specified"
	exit 1
    fi

    ARGS=
    if [ ! -z "$RUSER" ] ; then
	ARGS=":arg name user \"$RUSER\""
    fi
    if [ ! -z "$RPASSWORD" ] ; then
	ARGS="$ARGS :arg name password \"$RPASSWORD\""
    fi
    if [ ! -z "$BASEDIR" ] ; then
	ARGS="$ARGS :arg name basedir \"$BASEDIR\""
    fi
    if [ ! -z "$DECOMP" ] ; then
	ARGS="$ARGS :arg name decompress $DECOMP"
    fi

    if [ -z "$DESC" ] ; then
        DESC_ARG=
    else
        DESC_ARG=":description \"$DESC\""
    fi

    SCRIPT=/tmp/webdavsink_$$
    cat > $SCRIPT <<EOF
            sink.add :name "$NAME" \
	        :destination < \
                    :type "$TYPE" :arg -name url "$URL" \
                    $ARGS
                > \
            $DESC_ARG
EOF
}

scp() {
    PORT=22
    DECOMP=false
    NOHOSTKEY=0
    HOSTKEY=
    PKFILE=
    BASEDIR=
    FILEMODE=
    RUSER=
    RPASSWORD=
    while [ $# -gt 0 ] ; do
	case $1 in
	    --host)
		expect 1 "$@"
		HOST="$2"
		shift 2
		;;
	    --port)
		expect 1 "$@"
		PORT="$2"
		shift 2
		;;
	    --desc*)
		expect 1 "$@"
		DESC="$2"
		shift 2
		;;
	    --decomp*)
		DECOMP=true
		shift
		;;
	    --hostkey)
		expect 1 "$@"
		HOSTKEY="$2"
		shift 2
		;;
	    --nohostkey)
		NOHOSTKEY=1
		shift
		;;
	    --filemode)
		expect 1 "$@"
		FILEMODE="$2"
		shift 2
		;;
            --basedir)
		expect 1 "$@"
		BASEDIR="$2"
		shift 2
		;;
	    --user)
		expect 1 "$@"
		RUSER="$2"
		shift 2
		;;
	    --password)
		expect 1 "$@"
		RPASSWORD="$2"
		shift 2
		;;
	    --password-key)
		expect 1 "$@"
		RPASSWORD=swkey:$2
		shift 2
		;;
	    --pk-key)
		expect 1 "$@"
		PK=swkey:$2
		shift 2
		;;
	    --pkfile)
		expect 1 "$@"
		PK=`cat $2`
		shift 2
		;;
	    --pk-passphrase)
		expect 1 "$@"
		PASSPHRASE="$2"
		shift 2
		;;
	    --pk-passphrase-key)
		expect 1 "$@"
		PASSPHRASE=swkey:$2
		shift 2
		;;
	    --*)
		echo "unknown option $1"
		exit 1
		;;
	esac
    done

    if [ -z "$DESC" ] ; then
        DESC_ARG=
    else
        DESC_ARG=":description \"$DESC\""
    fi

    SCRIPT=/tmp/sshsink_$$
    if [ -z "$HOST" ] ; then
	cat > $SCRIPT <<EOF
            sink.add :name "$NAME" \
	        :destination < \
                    :type "$TYPE" :arg -name port "$PORT" \
                    :arg -name decompress "$DECOMP" \
                > \
            $DESC_ARG
EOF
	return
    fi

    ARGS=
    if [ ! -z "$RUSER" ] ; then
	ARGS="$ARGS :arg -name user \"$RUSER\""
    fi
    if [ ! -z "$RPASSWORD" ] ; then
	ARGS="$ARGS :arg -name password \"$RPASSWORD\""
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
    if [ ! -z "$PK" ] ; then
 	ARGS="$ARGS :arg -name prvkey \"$PK\""
    fi
    if [ ! -z "$PASSPHRASE" ] ; then
 	ARGS="$ARGS :arg -name passphrase \"$PASSPHRASE\""
    fi

    cat > $SCRIPT <<EOF
        sink.add :name "$NAME" \
	    :destination < \
                :type "$TYPE" :arg -name host "$HOST" \
	        :arg -name port "$PORT" \
                :arg -name decompress "$DECOMP" \
                $ARGS \
            > \
            $DESC_ARG
EOF
}

removesink() {
    if [ $# -ne 1 ] ; then
	echo "Error: expected a <sinkname>"
        exit 1
    fi
    $MFCOMMAND logon $MFLUX_DOMAIN $MFLUX_USER $MFLUX_PASSWORD
    $MFCOMMAND sink.remove :name $1
    RC=$?
    $MFCOMMAND logoff
}

listsinks() {
    if [ $# -ne 0 ] ; then
	echo "Error: no arguments or options expected"
        exit 1
    fi
    $MFCOMMAND logon $MFLUX_DOMAIN $MFLUX_USER $MFLUX_PASSWORD
    $MFCOMMAND sink.list
    RC=$?
    $MFCOMMAND logoff
}

describesink() {
    if [ $# -ne 1 ] ; then
	echo "Error: expected a <sinkname>"
        exit 1
    fi
    $MFCOMMAND logon $MFLUX_DOMAIN $MFLUX_USER $MFLUX_PASSWORD
    $MFCOMMAND sink.describe :name $1
    RC=$?
    $MFCOMMAND logoff
}

help() {
    if [ $# -eq 0 ]; then
	echo "Usage: $CMD subcommand [<args>]"
	echo "where the subcommands are:"
	echo "    add <sinkname> <type> --desc <description> ..."
        echo "                             - defines a sink"
	echo "    describe <sinkname>      - describes a sink"
	echo "    help [ <subcommand> ...] - outputs command help"
	echo "    list                     - lists all registered sinks"
	echo "    remove <sinkname>        - removes a sink"
        echo
	echo "$CMD manages DaRIS / Mediaflux sinks from the command line."
        echo "The command requires Mediaflux administrator privilege; i.e."
        echo "it needs to be run as the 'mflux' user, or as 'root'."
        echo 
    else
	case $1 in
	    add)
		shift
		helpadd "$@"
		;;
	    help)
		echo "$CMD help                  - shows command help"
		echo "$CMD help <subcommand> ... - shows subcommand help"
		;;
	    describe)
		echo "Usage: $CMD describe <sinkname>"
                echo 
                echo "This subcommand uses the Mediaflux 'sink.describe' "
                echo "service to output the named sink's configuration"
		;;
	    list)
		echo "Usage: $CMD list"
                echo
                echo "This subcommand uses the Mediaflux 'sink.list' service"
                echo "to list all sinks"
		;;
	    remove)
		echo "$CMD remove <sinkname>"
                echo
                echo "This subcommand uses the Mediaflux 'sink.remove' service"
                echo "to remove the named sink"
		;;
	    *)
		echo "Unknown subcommand '$1'.  Supported commands are 'add'"
                echo "'help', 'list' and 'remove'" 
		;;
	esac
    fi
    exit 1
}

helpadd() {
    if [ $# -eq 0 ]; then
	echo "Usage: $CMD add <sinkname> <type> ..."
	echo "   where <sinkname> is a sink name and <type> is the sink type"
        echo 
        echo "This subcommand defines a Mediaflux sink.  The supported types"
        echo "are 'scp', 'webdav', 'owncloud' or 'filesystem'."
        echo 
        echo "Use '$CMD help add <type>' for the options for each sink type."
        echo "Please refer to the DaRIS wiki or the Mediaflux documentation"
        echo "for more information on configuring sinks."
    else
	case $1 in
	    scp)
		helpscp
		;;
	    webdav)
		helpwebdav
		;;
	    owncloud)
		helpowncloud
		;;
	    filesystem)
		helpfs
		;;
	    *)
		echo "Unknown sink type $1"
		echo "Valid types are 'scp', 'webdav', 'owncloud' or 'filesystem'"
		;;
	esac
    fi
}

helpscp() {
    echo "Usage: $CMD add <sinkname> scp [ --host <host> ]" 
    echo "    [ --port <port> ] [ --hostkey <hostkey> ] [ --nohostkey ]"
    echo "    [ --user <user> ] [ --password <pwd> | --password-key <key> ]" 
    echo "    [ --pk-file <file> | --pk-key <key> ]"
    echo "    [ --passphrase <passphrase> | --passphrase-key <key> ]"
    echo "    [ --decomp ] [ --filemode <mode> ] [ --basedir <path> ]" 
    echo "    [ --desc '<description string>' ]" 
    echo 
    echo "This command adds an SSH/SCP sink.  The sink can be generic, or"
    echo "you can provide a specific host, authorization and other details."
    echo "RSA and IPv4 are assumed by this script, and the default port is"
    echo "the standard SSH port.  Many options are ignored for generic sinks."
    echo ""
    echo "Host identification: The --host can be specified either as a DNS"
    echo "name or as an IPv4 address.  The --hostkey (if provided) is used"
    echo "for definitive SSH host identification to guard against spoofing"
    echo "or man-in-the-middle attacks.  If neither --hostkey or --nohostkey"
    echo "is given, ssh-scankeys is run to find the RSA hostkey for the host."
    echo "If you set --nohostkey, the sink will not verify the identity of"
    echo "the remote host when the user does a transfer.  If you provide a"
    echo "hostkey explicitly, it must be an RSA hostkey."
    echo ""
    echo "Authorization: If --user is given, a password or private key is"
    echo "required also.  If a private key is required, you can supply a"
    echo "corresponding passphrase.  The password, private key and passphrase"
    echo "can be either provided directly (BAD!) or by giving a secure wallet"
    echo "key (GOOD!).  In the latter case, the actual credentials will be"
    echo "retrieved from the current user's wallet when the sink is used." 
    echo
    echo "NOTE: putting end-user credentials into a sink definition is"
    echo "insecure because they are visible to anyone with Mediaflux admin"
    echo "privilege, or system-level 'root' privilege.  Furthermore, any"
    echo "credentials in a sink definition will be shared by all users." 
    echo ""
    echo "Other options: if --basedir is provided, it is the default base"
    echo "directory for the host.  Otherwise, the default base location is the"
    echo "the (remote) user's (remote) home directory.  The --filemode is the"
    echo "the default UNIX/Linux file mode for copied files: default 0660.  The"
    echo "--decomp option enables automatic decompression of the asset by the"
    echo "sink.  This is disabled by default.  If enabled, the user's data is"
    echo "decompressed on the server, and transferred in uncompressed form."
}

helpowncloud() {
    echo "Usage: $CMD add <sinkname> owncloud --url <url>" 
    echo "    [ --user <user> ] [ --password <pwd> | --password-key <key> ]"
    echo "    [ --basedir <path> ] [ --decomp | --nodecomp ]"
    echo "    [ --chunked | --unchunked ] "
    echo "    [ --desc '<description string>' ]"
    echo 
    echo "This command adds an OwnCloud compatible sink.  The <url> is "
    echo "mandatory and should be the WebDAV base URL for the service.  It"
    echo "is recommended that you use an https URL rather than http."
    echo ""
    echo "Authentication: The --user and --password or --password-key provide"
    echo "owncloud user credentials."
    echo
    echo "NOTE: putting end-user credentials into a sink definition is"
    echo "insecure because they are visible to anyone with Mediaflux admin"
    echo "privilege, or system-level 'root' privilege.  Furthermore, any"
    echo "credentials in a sink definition will be shared by all users." 
    echo ""
    echo "Other options: The --decomp/--nodecomp options control decompression" 
    echo "of the asset by the sink.  This is disabled by default.  If enabled,"
    echo "the user's data is decompressed on the server, and transferred in"
    echo "uncompressed form.  The --chunked/--unchunked options control"
    echo "chunking.  This is enabled by default.  The --basedir option sets "
    echo "the directory within the owncloud tree."
}

helpwebdav() {
    echo "$CMD add <sinkname> webdav --url <url>" 
    echo "    [ --user <user> ] [ --password <pwd> | --password-key <key> ]"
    echo "    [ --basedir <path> ] [ --decomp | --nodecomp ]"
    echo "    [ --desc '<description string>' ]" 
    echo "This command adds an OwnCloud compatible sink.  The <url> is "
    echo "mandatory and should be the WebDAV base URL for the service.  It"
    echo "is recommended that you use an https URL rather than http."
    echo ""
    echo "Authentication: The --user and --password or --password-key provide"
    echo "owncloud user credentials."
    echo
    echo "NOTE: putting end-user credentials into a sink definition is"
    echo "insecure because they are visible to anyone with Mediaflux admin"
    echo "privilege, or system-level 'root' privilege.  Furthermore, any"
    echo "credentials in a sink definition will be shared by all users." 
    echo ""
    echo "Other options: The --decomp/--nodecomp options control decompression" 
    echo "of the asset by the sink.  This is disabled by default.  If enabled,"
    echo "the user's data is decompressed on the server, and transferred in"
    echo "uncompressed form.  The --basedir option sets the directory within"
    echo "the WebDAV tree."
}

helpfs() {
    echo "Usage $CMD add <sinkname> filesystem --directory <dir>" 
    echo "    [ --decomp <levels> ] [ --path <path> ] [ --save <saved> ]"
    echo "    [ --desc '<description string>' ]"
    echo 
    echo "This command adds a file-system sink.  The <dir> is mandatory and"
    echo "should give the absolute path to an existing directory that is"
    echo "writeable by the Linux mediaflux user (mflux).  This will be the root"
    echo "directory of the sink."
    echo ""
    echo "Other options: The --decomp option controls automatic decompression "
    echo "of the asset by the sink.  The --save says what should be saved by"
    echo "the sink.  The <saved> value is one of 'meta', 'content' or 'both'."
    echo "The default is 'content'.  The --path optoin gives a path relative"
    echo "to the sink's root directory."
    echo ""
    echo "Both the <dir> and <path> strings can contain metadata references"
    echo "that will be substituted when the sink is used.  Refer to the DaRIS"
    echo "wiki or the Mediaflux documentation."
}


if [ $# -eq 0 ] ; then
    help
fi

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
  -*)
    help
    ;;
  *)
    echo "Unknown subcommand '$1' - run '$CMD help' for help"
    exit 1
    ;;
esac
exit $RC
