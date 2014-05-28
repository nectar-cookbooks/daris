#!/bin/sh
#
# Admin command for configuring kepler workflows, etc

. /etc/mediaflux/servicerc
if [ $? -ne 0 ]; then
    exit 1
fi

MFCOMMAND=${MFLUX_BIN}/mfcommand

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

provider() {
    if [ $# -eq 0 ] ; then
	echo "syntax: provider --user user --host host <options> ..."
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
	    --user)
		expect 1 "$@"
		DUSER="$2"
		shift 2
		;;
	    --host)
		expect 1 "$@"
		RHOST="$2"
		shift 2
		;;
	    --remote-user)
		expect 1 "$@"
		RUSER="$2"
		shift 2
		;;
	    --pk-key)
		expect 1 "$@"
		PK_KEY="$2"
		shift 2
		;;
	    --password-key)
		expect 1 "$@"
		PWD_KEY="$2"
		shift 2
		;;
            --kpath)
		expect 1 "$@"
		KPATH="$2"
		shift 2
		;;		
            --kcommand)
		expect 1 "$@"
		KCMD="$2"
		shift 2
		;;		
	    -*)
		echo "Unrecognized option $1"
		RC=1
		exit
		;;
	    *)
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
    SCRIPT=/tmp/keplerconfig_$$
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
                    $CREDENTIALS \
                    :command "${KPATH}/${KCMD}" \
                 > \
                 :port-xpath stdout \
            > \
        > \
    >
EOF
    $MFCOMMAND logon $MFLUX_DOMAIN $MFLUX_USER $MFLUX_PASSWORD
    $MFCOMMAND source $SCRIPT
    RC=$?
    $MFCOMMAND logoff
    rm $SCRIPT
    
}

workflow() {
   if [ $# -lt 1 ] ; then
       echo "syntax: $0 workflow <workflow.kar> [--name <name>] "
       RC=1
       exit
   fi
   WF=$1
   shift
   NAME=
   SCRIPT=/tmp/keplerconfig_$$
   SCRIPT_2=/tmp/keplerconfig_$$_2
   rm -f $SCRIPT $SCRIPT_2
   touch $SCRIPT_2
   while [ $# -gt 0 ] ; do
       case $1 in
	   --name)
	       expect 1 "$@"
	       NAME=$2
	       shift 2
	       ;;
           --param)
	       expect 2 "$@"
	       PARAM_ARGS="-name \"$2\" -type \"$3\""
	       shift 3
	       while [ $# -gt 0 ] ; do
		   case $1 in
		       --min-occurs)
			   expect 1 "$@"
                           PARAM_ARGS="$PARAM_ARGS -min-occurs $2"
                           shift 2
			   ;;
		       --max-occurs)
                           shift 2
                           PARAM_ARGS="$PARAM_ARGS -max-occurs $2"
			   expect 1 "$@"
			   ;;
		       --value)
			   expect 1 "$@"
			   PARAM_VALUE="$2"
                           shift 2
			   ;;
		       --*)
			   echo "Unknown --param option $1"
			   exit
			   ;;
		       *)
			   echo "Unexpected --param argument $1"
			   exit
			   ;;
		   esac
	       done
	       if [ -z "$PARAM_VALUE" ] ; then
		   cat >> $SCRIPT_2 <<EOF
               :parameter $PARAM_ARGS \\
EOF
	       else
		   cat >> $SCRIPT_2 <<EOF
               :parameter $PARAM_ARGS < :value \"$PARAM_VALUE\" > \\
EOF
               fi
	       ;;
	   --*)
	       echo "Unknown option $1"
	       exit
	       ;;
	   *)
	       echo "Unexpected argument $1"
	       exit
	       ;;
       esac
   done

   if [ -z "$NAME" ] ; then
       NAME=`basename $WF .kar`
   fi
   cat >> $SCRIPT <<EOF
       set uid [xvalue //*\[@name='$NAME'\]/@uid \
                    [transform.definition.list]]
       if { [ string length \$uid ] == 0} {
           transform.definition.create :type kepler :name \"$NAME\" \\
               :in file:$WF \\
EOF
   cat >> $SCRIPT < $SCRIPT_2
   cat >> $SCRIPT <<EOF
       } else {
           transform.definition.update :uid \$uid :name \"$NAME\" \\
               :in file:$WF \\
EOF
   cat >> $SCRIPT < $SCRIPT_2
   cat >> $SCRIPT <<EOF
       }
EOF

    $MFCOMMAND logon $MFLUX_DOMAIN $MFLUX_USER $MFLUX_PASSWORD
    $MFCOMMAND source $SCRIPT
    RC=$?
    $MFCOMMAND logoff
    rm $SCRIPT $SCRIPT_2
}

method() {
    if [ $# -lt 1 ] ; then
	echo "usage: $0 method <name> [--update] (--workflow <name> <options>) ..."
	RC=1
	exit
    fi
    NAME=$1
    shift
    SCRIPT=/tmp/keplerconfig_$$
    SCRIPT_2=/tmp/keplerconfig_$$_2
    SCRIPT_3=/tmp/keplerconfig_$$_3
    UPDATE=0
    rm -f $SCRIPT $SCRIPT_2
    while [ $# -gt 0 ] ; do
        if [ "$1" == "update" ] then
            UPDATE=1
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
		--name)
 		    expect 1 "$@"
		    STEP_NAME=$2
		    shift 2
		    ;;
		--param)
		    expect 2 "$@"
		    PARAM=$2
		    VALUE=$3
		    shift 3
		    cat >> $SCRIPT_3 <<EOF
                    :parameter -name $PARAM \"$VALUE\" \\
EOF
		    ;;
		--iterator)
		    expect 4 "$@"
		    SCOPE=$1
		    TYPE=$2
		    QUERY=$3
		    PARAM=$4
                    shift 5
		    cat >> $SCRIPT_3 <<EOF
                    :iterator < \\
                        :parameter $PARAM \\
                        :query \"$QUERY\" \\
                        :scope $SCOPE \\
                        :type $TYPE \\
                    > \\
EOF
		    ;;
		--workflow)
		    break
		    ;;
	    esac
	done
	cat >> $SCRIPT_2 <<EOF
            :step < \\
                :name \"$WF_NAME\" \\
                :transform < \\
                    :definition -version 0 \$wf_${WF_NAME}_uid \\
EOF
	cat >> $SCRIPT_2 < $SCRIPT_3
        cat >> $SCRIPT_2 <<EOF
                > \\
            > \\
EOF
    done
    if [ $UPDATE = 1 ] ; then
	VERB="om.pssd.method.for.subject.update :replace true"
    else
	VERB="om.pssd.method.for.subject.create"
    fi
    cat >> $SCRIPT <<EOF
        $VERB :name \"$NAME\" :namespace "/pssd/methods" \\
            :description \"Workflow collection $NAME\" \\
            :subject < :project <> > \\
EOF
    cat >> $SCRIPT < $SCRIPT_2

    $MFCOMMAND logon $MFLUX_DOMAIN $MFLUX_USER $MFLUX_PASSWORD
    $MFCOMMAND source $SCRIPT
    RC=$?
    $MFCOMMAND logoff
    rm -f $SCRIPT $SCRIPT_2 $SCRIPT_3
}

help() {
    echo "Don't panic!"
    RC=1
    exit
}

case "$1" in 
  provider) 
    shift
    provider "$@"
    ;;

  workflow)
    shift
    workflow "$@"
    ;;

  method)
    shift
    method "$@"
    ;;

  help)
    shift 
    help "$@"
    ;;

  *)
    help
    RC=1
    ;;
esac

exit $RC

