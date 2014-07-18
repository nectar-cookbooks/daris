#!/bin/sh
#
# Command for configuring access to the user's filespace by a remote 
# Mediaflux instance using an SSH sink.  This entails: 
#   1) Creating a new SSH key pair for the user
#   2) Adding the public key to the user's "authorized_keys" file
#   3) Logging into Mediaflux as the user and adding the private key
#      to the user's secure wallet.

if [ -r /etc/mediaflux/mfluxrc ] ; then
    . /etc/mediaflux/mfluxrc
fi
if [ -r $HOME/.mfluxrc ] ; then
    . $HOME/.mfluxrc
fi

if [ -z "$MFLUX_BIN" ] ; then
    MFCOMMAND=mfcommand
else
    MFCOMMAND=${MFLUX_BIN}/mfcommand
fi

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

usage() {
    echo "Usage: $CMD [ --user <mflux-user> ] [ --domain <mflux-domain> ]"
    echo "            [ --key-key <name> ] [ --host <host> ] [ --port <no> ]"
    echo "            [ --transport <transport> ]"
}

help() {
    usage
    echo "This command enables SSH-sink access for a given Mediaflux user"
    echo "to the current user's filespace on this machine.  This is done by"
    echo "generating a passphrase-less SSH keypair, adding the public key to"
    echo "the user's 'authorized_keys' file, and uploading the private key"
    echo "to the mediaflux user's secure wallet.  You will be prompted for"
    echo "the mediaflux user's password.  Other parameters can be supplied"
    echo "via command options, or environment variables set in the user's" 
    echo "'.mfluxrc' file."
    echo
    echo "Options:"
    echo "  --user <mflux_user> The mediaflux user name (\$MFLUX_USER)"
    echo "  --domain <mflux_domain> The mediaflux domain (\$MFLUX_DOMAIN)"
    echo "  --host <host> The mediaflux server hostname (\$MFLUX_HOST)"
    echo "  --host <port> The mediaflux server port (\$MFLUX_PORT)"
    echo "  --transport <transport> The mediaflux transport (\$MFLUX_TRANSPORT)"
    echo "  --key-key <name> The mediaflux wallet key-key; defaults to 'pk'."
}

KEY_KEY=pk

while [ $# -gt 0 ] ; do
    case $1 in
	--user)
	    expect 1 "$@"
	    MFLUX_USER=$2
	    shift 2
	    ;;
	--domain)
	    expect 1 "$@"
	    MFLUX_DOMAIN=$2
	    shift 2
	    ;;
	--host )
	    expect 1 "$@"
	    MFLUX_HOST=$2
	    shift 2
	    ;;
	--port )
	    expect 1 "$@"
	    MFLUX_PORT=$2
	    shift 2
	    ;;
	--transport )
	    expect 1 "$@"
	    MFLUX_TRANSPORT=$2
	    shift 2
	    ;;
	--key-key )
	    expect 1 "$@"
	    KEY_KEY=$2
	    shift 2
	    ;;
	-h | --help)
	    help
            exit 0
	    ;;
	-*)
	    echo "Unrecognized option"
	    usage
            exit 1
	    ;;
	*)
	    break
	    ;;
    esac
done

if [ -z "$MFLUX_USER" ] ; then 
    echo "Use --user to supply the Mediaflux / DaRIS user name"
    exit 1
fi

if [ -z "$MFLUX_DOMAIN" ] ; then 
    echo "Use --domain to supply the Mediaflux / DaRIS user domain"
    exit 1
fi

if [ -z "$MFLUX_HOST" ] ; then 
    echo "Use --host to supply the Mediaflux / DaRIS server hostname"
    exit 1
fi

if [ -z "$MFLUX_PORT" ] ; then 
    echo "Use --port to supply the Mediaflux / DaRIS server port"
    exit 1
fi

read -s -p "Password for mediaflux user $MFLUX_USER:  " MFLUX_PASSWORD
echo

if [ -z "$MFLUX_PASSWORD" ] ; then
    echo "No password supplied: bailing out"
    exit 1
fi
if [ ! -d $HOME/.ssh ] ; then
    echo "There is no '.ssh' directory in your HOME directory ($HOME)"
    exit 1
fi
if [ ! -r $HOME/.ssh -o ! -w $HOME/.ssh -o ! -x $HOME/.ssh ] ; then
    echo "You can't access your '\$HOME/.ssh' directory!"
    exit 1
fi
KEY_PAIR=${MFLUX_USER}_${MFLUX_HOST}_rsa
TAG="${MFLUX_USER}@${MFLUX_HOST} - mediaflux"
if [ -e $HOME/.ssh/$KEY_PAIR ] ; then
    echo "Recreating the key-pair $KEY_PAIR"
else
    echo "Creating a new key-pair $KEY_PAIR"
fi
rm $HOME/.ssh/${KEY_PAIR} $HOME/.ssh/${KEY_PAIR}.pub
ssh-keygen -q -t rsa -N "" -C "$TAG" -f $HOME/.ssh/${KEY_PAIR}
if [ $? -ne 0 ] ; then
    echo "SSH key generation failed"
    exit 1
fi

echo "Adding the public key to 'authorized_keys'"
AK=$HOME/.ssh/authorized_keys
if [ -e $AK ] ; then
    grep -v "$TAG" $AK > $AK.tmp
    cat $HOME/.ssh/${KEY_PAIR}.pub >> $AK.tmp
    mv $AK.tmp $AK
else
    cp $HOME/.ssh/${KEY_PAIR}.pub $ak
fi
chmod 600 $AK

echo "Adding the private key to ${MFLUX_USER}'s secure wallet (as '$KEY_KEY')"
SCRIPT=$HOME/.ssh/mflux_script
KEY=`sed '{:q;N;s/\n/\\\\n/g;t q}' < $HOME/.ssh/${KEY_PAIR}`
cat <<EOF > $SCRIPT
secure.wallet.set :key \"$KEY_KEY\" :value \"$KEY\"
EOF
$MFCOMMAND --norc logon $MFLUX_DOMAIN $MFLUX_USER $MFLUX_PASSWORD
if [ $? -ne 0 ] ; then
    echo "Mediaflux login failed for domain $MFLUX_DOMAIN, user $MFLUX_USER"
    exit 1
fi
$MFCOMMAND --norc source $SCRIPT
RC=$?
$MFCOMMAND --norc logoff
rm $SCRIPT

if [ $RC -eq 0 ] ; then
    echo "Succeeded"
fi
exit $RC
