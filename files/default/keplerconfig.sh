#!/bin/sh
#
# Admin command for configuring kepler workflows, etc

. /etc/mediaflux/servicerc
if [ $? -ne 0 ]; then
    exit 1
fi

MFCOMMAND=${MFLUX_BIN}/mfcommand

provider() {
   if [ $# -eq 3 ] ; then
       KEPLER=/usr/local/kepler
   elif [ $# -eq 4 ] ; then
       KEPLER="$4"
   else
       echo "syntax: $0 provider <host> <user> <password> [ <kepler-dir> ]"
       RC=1
       exit
   fi
   SCRIPT=/tmp/keplerconfig_$$
   cat > $SCRIPT <<EOF
transform.provider.user.settings.set \
    :domain users :user "$2" \
    :type kepler \
    :settings < \
        :kepler.server < \
            :host "$1" \
            :launcher-service -name secure.shell.execute < \
                :args < \
                    :host "$1" \
                    :user  < :name "$2" :password "$3" > \
                    :command "$KEPLER/keplernk.sh --single" \
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
   while [ $# -gt 0 ] ; do
       case $1 in
	   --name)
	       NAME=$2
	       shift 2
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

   SCRIPT=/tmp/keplerconfig_$$
   if [ -z "$NAME" ] ; then
       NAME=`basename $WF .kar`
   fi
   cat >> $SCRIPT <<EOF
       set uid [xvalue //*\[@name='$NAME'\]/@uid \
                    [transform.definition.list]]
       if { [ string length \$uid ] == 0} {
           transform.definition.create :type kepler :name \"$NAME\" :in file:$WF
       } else {
           transform.definition.update :uid \$uid :name \"$NAME\" :in file:$WF
       }
EOF

    $MFCOMMAND logon $MFLUX_DOMAIN $MFLUX_USER $MFLUX_PASSWORD
    $MFCOMMAND source $SCRIPT
    RC=$?
    $MFCOMMAND logoff
    rm $SCRIPT
}

method() {
    if [ $# -lt 1 ] ; then
	echo "syntax: $0 method <name> [ <workflow> ... ] "
	RC=1
	exit
    fi
    NAME=$1
    shift
    SCRIPT=/tmp/keplerconfig_$$
    SCRIPT_2=/tmp/keplerconfig_$$_2
    NOS_WORKFLOWS=$#
    rm -f $SCRIPT $SCRIPT_2
    while [ $# -gt 0 ] ; do
	WF_NAME=$1
	shift
	cat >> $SCRIPT <<EOF
        set wf_${WF_NAME}_uid [xvalue //*\[@name='$WF_NAME'\]/@uid \\
                                  [transform.definition.list]]
EOF
	cat >> $SCRIPT_2 <<EOF
            :step < \\
                :name \"$WF_NAME\" \\
                :transform < \\
                    :definition -version 0 \$wf_${WF_NAME}_uid \\
                > \\
            > \\
EOF
    done
    cat >> $SCRIPT <<EOF
        om.pssd.method.create :name \"$NAME\" :namespace "/pssd/methods" \\
            :description \"Workflow collection $NAME\" \\
EOF
    cat >> $SCRIPT < $SCRIPT_2

    $MFCOMMAND logon $MFLUX_DOMAIN $MFLUX_USER $MFLUX_PASSWORD
    $MFCOMMAND source $SCRIPT
    RC=$?
    $MFCOMMAND logoff
    rm $SCRIPT $SCRIPT_2
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

