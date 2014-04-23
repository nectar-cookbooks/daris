#!/bin/sh
#
# Admin command for configuring kepler workflows, etc

. /etc/mediaflux/mediafluxrc


KEPLER=/usr/local/kepler
MFCOMMAND=${MFLUX_BIN}/mfcommand

provider() {
   if [ $# -eq 3 ] ; then
       # ...
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
   if [ $# -ne 1 ] ; then
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
       set uid [xvalue //*\[@name='SNAME'\]/@uid \
                       [transform.definition.list]]
       if {$uid == '') {
           transform.definition.create :type kepler :name $NAME :in file:$WF
       } else {
           transform.definition.update :uid \$uid :name $NAME :in file:$WF
       }
EOF

    $MFCOMMAND logon $MFLUX_DOMAIN $MFLUX_USER $MFLUX_PASSWORD
    $MFCOMMAND source $SCRIPT
    RC=$?
    $MFCOMMAND logoff
    rm $SCRIPT
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

