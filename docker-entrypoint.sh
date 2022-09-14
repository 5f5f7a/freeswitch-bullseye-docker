#!/bin/sh
BASEURL=http://files.freeswitch.org
PID_FILE=/var/run/freeswitch/freeswitch.pid
get_password() {
    < /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-12};echo;
}

get_sound_version() {
    local SOUND_TYPE=$1
    grep "$SOUND_TYPE" sounds_version.txt | sed -E "s/$SOUND_TYPE\s+//"
}

wget_helper() {
    local SOUND_FILE=$1
    grep -q $SOUND_FILE /usr/share/freeswitch/sounds/soundfiles_present.txt 2> /dev/null
    if [ "$?" -eq 0 ]; then
        echo "Skipping download of $SOUND_FILE. Already present"
        return
    fi
    wget $BASEURL/$SOUND_FILE
    if [ -f $SOUND_FILE ]; then
        echo $SOUND_FILE >> /usr/share/freeswitch/sounds/soundfiles_present.txt
    fi
}
if [ ! -f "/etc/freeswitch/freeswitch.xml" ]; then
    SIP_PASSWORD=$(get_password)
    mkdir -p /etc/freeswitch
    cp -varf /usr/share/freeswitch/conf/vanilla/* /etc/freeswitch/
    sed -i -e "s/default_password=.*\?/default_password=$SIP_PASSWORD\"/" /etc/freeswitch/vars.xml
    echo "New FreeSwitch password for SIP calls set to '$SIP_PASSWORD'"
fi

trap '/usr/bin/freeswitch -stop' SIGTERM
/usr/bin/freeswitch -nc -nf -nonat &
pid="$!"

wait $pid
exit 0
