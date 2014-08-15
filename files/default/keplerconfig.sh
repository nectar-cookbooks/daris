#!/bin/sh
#
# Admin command for configuring kepler workflows, etc

. /etc/mediaflux/servicerc
if [ $? -ne 0 ]; then
    exit 1
fi

MFCOMMAND=${MFLUX_BIN}/mfcommand
DEBUG=0
RC=0
CMD=`basename $0`
SCRIPT_BASE=/tmp/keplerconfig_$$

expect() {
    EXPECTED=$1
    KEYWORD=$2
    shift 2
    if [ $# -lt $EXPECTED ] ; then
        if [ $EXPECTED -eq 1 ] ; then
	    echo "syntax error: expected a value after '$KEYWORD'"
	else
	    echo "syntax error: expected $EXPECTED values after '$KEYWORD'"
	fi
	RC=1
	exit
    fi
}

run() {
    $MFCOMMAND logon $MFLUX_DOMAIN $MFLUX_USER $MFLUX_PASSWORD
    $MFCOMMAND source "$1"
    RC=$?
    $MFCOMMAND logoff

    if [ $DEBUG -eq 0 ] ; then
	rm "$@"
    fi
}

provider() {
    if [ $# -eq 0 ] ; then
	echo "syntax: $CMD provider --user user --host host <options> ..."
        RC=1
	exit
    fi
    DUSER=
    RUSER=
    RHOST=
    PK_KEY=
    PWD_KEY=
    KPATH="/mnt/Applications/kepler-2.4"
    KCMD="keplernk.sh --single"
    while [ $# -gt 0 ] ; do
	case $1 in
	    --user )
		expect 1 "$@"
		DUSER="$2"
		shift 2
		;;
	    --host )
		expect 1 "$@"
		RHOST="$2"
		shift 2
		;;
	    --remote-user )
		expect 1 "$@"
		RUSER="$2"
		shift 2
		;;
	    --pk-key )
		expect 1 "$@"
		PK_KEY="$2"
		shift 2
		;;
	    --password-key )
		expect 1 "$@"
		PWD_KEY="$2"
		shift 2
		;;
            --kpath )
		expect 1 "$@"
		KPATH="$2"
		shift 2
		;;		
            --kcommand )
		expect 1 "$@"
		KCMD="$2"
		shift 2
		;;		
	    -* )
		echo "Unrecognized option $1"
		RC=1
		exit
		;;
	    * )
		echo "Unexpected argument $1"
		RC=1
		exit
		;;
	esac
    done
    if [ -z "$DUSER" -o -z "$RHOST" ] ; then
	echo "usage error: the --user and --host options are mandatory"
	RC=1
	exit
    fi
    if [ -z "$RUSER" ] ; then
	RUSER="$DUSER"
    fi
    if [ -z "$PK_KEY" ] ; then
        if [ -z "$PWD_KEY" ] ; then
	    echo "usage error: you must specify a secure wallet keyname for " \
		"either the user's password or private key"
	    RC=1
	    exit
	fi
        CREDENTIALS=":user < :name \"$RUSER\" :password-key \"$PWD_KEY\" >"
    else
	CREDENTIALS=":private-key < :name \"$RUSER\" :key-key \"$PK_KEY\" >"
    fi
    SCRIPT=$SCRIPT_BASE
    cat > $SCRIPT <<EOF
transform.provider.user.settings.set \
    :domain users :user "$DUSER" \
    :type kepler \
    :settings < \
        :kepler.server < \
            :host "$RHOST" \
            :launcher-service -name secure.shell.execute < \
                :args < \
                    :host "$RHOST" \
                    :use-wallet-entry true \
                    :command "${KPATH}/${KCMD}" \
                 > \
                 :port-xpath stdout \
            > \
        > \
    >
EOF
    run $SCRIPT
    echo The users SSH private key for $RHOST must be provided as a secure
    echo wallet entry in the users wallet with the wallet key:
    echo "        " \"host-credentials:ssh:$RHOST\"
}

workflow() {
   if [ $# -lt 1 ] ; then
       echo "syntax: $CMD workflow <workflow.kar> [<options>] "
       RC=1
       exit
   fi
   WF=$1
   shift
   NAME=
   SCRIPT=$SCRIPT_BASE
   while [ $# -gt 0 ] ; do
       case $1 in
	   --name )
	       expect 1 "$@"
	       NAME=$2
	       shift 2
	       ;;
	   -* )
	       echo "Unknown option $1"
	       exit
	       ;;
	   * )
	       echo "Unexpected argument $1"
	       exit
	       ;;
       esac
   done

   if [ -z "$NAME" ] ; then
       NAME=`basename $WF .kar`
   fi
   cat > $SCRIPT <<EOF
set uid [xvalue //*\[@name='$NAME'\]/@uid [transform.definition.list]]
if { [ string length \$uid ] == 0} {
    transform.definition.create :type kepler :name \"$NAME\" :in file:$WF \\
} else {
    transform.definition.update :uid \$uid :name \"$NAME\" :in file:$WF \\
}
EOF
    run $SCRIPT
}

refresh() {
    if [ $# -lt 1 ] ; then
	echo "usage: $CMD refresh --all | <subject-cid> ..." 
    fi
    ALL=0
    while [ $# -gt 0 ] ; do 
	case "$1" in
	    --all )
		ALL=1
		shift
		;;
	    -* )
		echo "Unknown option $1"
		exit
		;;
	    *)
		break
		;;
	esac
    done
    SCRIPT=$SCRIPT_BASE
    if [ $ALL -eq 1 ] ; then
	cat > $SCRIPT << EOF
set res [ \\
      asset.query :where xpath(pssd-object/type)='subject' \\
                     and xpath(pssd-subject/method)='1036.2.25' \\
                  :action get-value :xpath cid ]
set method_cids [ xvalues //
EOF
    else
	SAVE_IFS="$IFS"
        IFS=","
	cat > $SCRIPT << EOF
set method_cids [ list "$*" ]
EOF
    fi
    cat >> $SCRIPT <<EOF
foreach S \$method_cids {
    om.pssd.subject.method.replace :id \$S :recursive true
}
EOF
    # run $SCRIPT
}


method() {
    if [ $# -lt 1 ] ; then
	echo "usage: $CMD method <name> [--update cid] "
        echo "          (--workflow <name> <options>) ..."
	RC=1
	exit
    fi
    NAME=$1
    shift
    SCRIPT=$SCRIPT_BASE
    SCRIPT_2=${SCRIPT_BASE}_2
    SCRIPT_3=${SCRIPT_BASE}_3
    UPDATE=
    rm -f $SCRIPT $SCRIPT_2
    while [ $# -gt 0 ] ; do
        if [ "$1" == "--update" ] ; then
            expect 1 "$@"
	    UPDATE=$2
	    shift 2
	    continue
        elif [ "$1" != "--workflow" ] ; then
	    echo "syntax error: expected a '--workflow' option - found '$1'"
	    RC=1
	    exit
	fi
	expect 1 "$@"
	WF_NAME=$2
        STEP_NAME=WF_NAME
	shift 2
	cat >> $SCRIPT <<EOF
set wf_${WF_NAME}_uid [xvalue //*\[@name='$WF_NAME'\]/@uid \\
                          [transform.definition.list]]
EOF
        rm -f $SCRIPT_3
        touch $SCRIPT_3
        while [ $# -gt 0 ] ; do
	    case $1 in
		--name )
 		    expect 1 "$@"
		    STEP_NAME=$2
		    shift 2
		    ;;
		--param )
		    expect 2 "$@"
		    PARAM=$2
		    VALUE=$3
		    shift 3
		    cat >> $SCRIPT_3 <<EOF
    :parameter -name $PARAM \"$VALUE\" \\
EOF
		    ;;
		--iterator )
		    expect 4 "$@"
		    SCOPE=$1
		    TYPE=$2
		    QUERY=$3
		    PARAM=$4
                    shift 5
		    cat >> $SCRIPT_3 <<EOF
    :iterator < :parameter $PARAM :query \"$QUERY\" \\
                :scope $SCOPE :type $TYPE > \\
EOF
		    ;;
		--workflow )
		    break
		    ;;
	    esac
	done
	cat >> $SCRIPT_2 <<EOF
    :step < :name \"$WF_NAME\" \\
            :transform < :definition -version 0 \$wf_${WF_NAME}_uid \\
EOF
	cat >> $SCRIPT_2 < $SCRIPT_3
        cat >> $SCRIPT_2 <<EOF
         > \\
    > \\
EOF
    done
    if [ -z "$UPDATE" ] ; then
	VERB="om.pssd.method.for.subject.create"
    else
	VERB="om.pssd.method.for.subject.update :id $UPDATE :replace true"
    fi
    cat >> $SCRIPT <<EOF
$VERB :name \"$NAME\" :namespace "/pssd/methods" \\
    :description \"Workflow collection $NAME\" \\
    :subject < :project <> > \\
EOF
    cat >> $SCRIPT < $SCRIPT_2

    run $SCRIPT $SCRIPT_2 $SCRIPT_3
}

help() {
    if [ $# -eq 0 ] ; then
	echo "Usage: $CMD <global-opts> subcommand [<args>]"
	echo "where the subcommands are:"
	echo "    provider --user user --host host <options>"
        echo "                             - sets the user's kepler provider settings"
	echo "   workflow <workflow.kar> [ <options> ]"
        echo "                             - creates or updates the DaRIS "
        echo "                               'transform definition' for a workflow "
	echo "    help [ <subcommand> ...] - outputs command help"
	echo "    method <methodname> <options> --workflow ... "
        echo "                             - creates or updates a DaRIS method"
	echo "                               containing 'transform steps' for"
	echo "                               one or more workflows"
        echo
	echo "$CMD configures the DaRIS side of the DaRIS / Kepler workflow"
        echo "integration from the command line.  The only global option is"
	echo "--debug (or -d) which causes the command keep the Mediaflux"
        echo "script files after they have been executed."
        echo
        echo "The command requires Mediaflux administrator privilege; i.e."
        echo "it needs to be run as the 'mflux' user, or as 'root'."
        echo 
    else
	case $1 in
	    method )
		shift
		helpmethod "$@"
		;;
	    help )
		echo "$CMD help                  - shows command help"
		echo "$CMD help <subcommand> ... - shows subcommand help"
		;;
	    workflow )
		shift
		helpworkflow "$@"
		;;
	    provider )
		shift
		helpprovider "$@"
		;;
	    * )
		echo "Unknown command '$1'.  Supported commands are 'method'"
                echo "'workflow', 'provider' and 'help'" 
		;;
	esac
    fi
    exit 1
}

helpmethod() {
    echo "Usage: $CMD method <methodname> [ --update <cid> ]" 
    echo "    ( --workflow <workflowname> "
    echo "           [ --name <stepname> ]"
    echo "           [ --param <pname> <type> ] ..."
    echo "           [ --iterator <scope> <type> <query> <param>] ... ) ..."
    echo 
    echo "This command either creates or updates a DaRIS 'Method' to hold a"
    echo "collection of workflows; e.g. previously defined using the 'workflow'"
    echo "subcommand."
    echo 
    echo "Updating a method requires the CID for the existing method.  Note"
    echo "this does not (yet) refresh any Ex-methods that were instantiated"
    echo "from the previous version."
    echo
    echo "Each workflow to be included in the method, needs a --workflow option"
    echo "followed by any options that relate to the particular workflow:"
    echo " - A '--name' option sets the method's 'step' name to the provided"
    echo "   value.  Otherwise the 'step' name defaults to the <workflowname>."
    echo " - A '--param' option specifies a workflow parameter and value to be"
    echo "   pre-filled by the DaRIS UI."
    echo "   Multiple parameters may be specified."
    echo " - An '--iterator' option specifies a transform iterator and its"
    echo "   attributes.  Ask the DaRIS team for details."
}


while [ $# -gt 0 ] ; do
    case $1 in
	--debug | -d )
	    DEBUG=1
            SCRIPT_BASE=/tmp/keplerconfig_debug
	    shift
	    ;;
	-* )
	    echo "Unknown option $1"
	    exit
	    ;;
	* )
	    break
	    ;;
    esac
done

case "$1" in 
  provider ) 
    shift
    provider "$@"
    ;;

  workflow )
    shift
    workflow "$@"
    ;;

  method )
    shift
    method "$@"
    ;;

  refresh )
    shift
    refresh "$@"
    ;;

  help )
    shift 
    help "$@"
    ;;

  * )
    help
    RC=1
    ;;
esac

exit $RC

