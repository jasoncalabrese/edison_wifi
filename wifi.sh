#!/bin/bash
##################################################################
# Author:    Kevin Reed (Dweeber)
#            dweeber.dweebs@gmail.com
#
# Copyright: Copyright (c) 2012 Kevin Reed <kreed@tnet.com>
#            https://github.com/dweeber/WiFi_Check
#
# Purpose:
#
# Script checks to see if WiFi has a network IP and if not
# restart WiFi
#
# Uses a lock file which prevents the script from running more
# than one at a time.  If lockfile is old, it removes it
#################################################################
# Instructions:
#
# o Install where you want to run it from like /home/edison/src/edison_wifi
# o chmod 0755 /home/edison/src/edison_wifi/wifi.sh
# o Add to crontab
# 
# Run Every 5 mins - Seems like ever min is over kill unless
# this is a very common problem.  If once a min change */5 to *
# once every 2 mins */5 to */2 ...
#
# REMOTE_HOST="google.com" # will be used to test network connectivity
# YOUR_HOME_NETOWRK=ssid_name  #change ssid_name to your primary network you want to use.  This will switch to that network if it is available.
# */5 * * * * ~/src/edison_wifi/wifi.sh $REMOTE_HOST
# sudo crontab -e  (to run cron from root)
# */15 * * * * ( (wpa_cli status | grep $YOUR_HOME_NETWORK > /dev/null && echo already on $YOUR_HOME_NETWORK) || (wpa_cli scan > /dev/null && wpa_cli scan_results | egrep $YOUR_HOME_NETWORK > /dev/null && wpa_cli select_network $(wpa_cli list_networks | grep $YOUR_HOME_NETWORK | cut -f 1) && echo switched to $YOUR_HOME_NETWORK && sleep 15 && (for i in $(wpa_cli list_networks | grep DISABLED | cut -f 1); do wpa_cli enable_network $i > /dev/null; done) && echo and re-enabled other networks) ) 2>&1 | logger -t wifi-select
##################################################################
# Settings
# Where and what you want to call the Lockfile
lockfile='/home/indy/edison_wifi/WiFi_Check.pid'
# Which Interface do you want to check/fix
wlan='wlan0'
pingip=$1
##################################################################
    # A lockfile exists... Lets check to see if it is still valid
    pid=`cat $lockfile`
    if kill -0 &>1 > /dev/null $pid; then
        # Still Valid... lets let it be...
        #echo "Process still running, Lockfile valid"
        exit 1
    else
        # Old Lockfile, Remove it
        #echo "Old lockfile, Removing Lockfile"
        rm $lockfile
    fi
fi
# If we get here, set a lock file using our current PID#
#echo "Setting Lockfile"
echo $$ > $lockfile

# We can perform check
/bin/ping -c 2 -I $wlan $pingip > /dev/null 2> /dev/null
if [ $? -ge 1 ] ; then
    echo "Network connection down! Attempting reconnection."
    /sbin/ifdown $wlan
    /bin/sleep 15
    /sbin/ifup --force $wlan
    /sbin/wpa_cli scan
    killall autossh
    killall ssh
else
    echo "Network is Okay"
fi

/sbin/ifconfig $wlan | grep "inet addr:"

# Check is complete, Remove Lock file and exit
#echo "process is complete, removing lockfile"
rm $lockfile
exit 0

##################################################################
# End of Script
##################################################################
