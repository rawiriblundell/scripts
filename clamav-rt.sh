#!/usr/bin/env bash

# Released under the DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE (WTFPL) 
# http://www.wtfpl.net/

# Author: Rawiri Blundell, 09/2014

# A script to be called by incrond.  Create the file /etc/incron.d/clamav with the contents:
# [Directory to watch] IN_CREATE,IN_CLOSE_WRITE,IN_ATTRIB /path/to/clam-rt.sh $@/$#
# e.g.
# /home/rawiri/Downloads IN_CREATE,IN_CLOSE_WRITE,IN_ATTRIB /home/rawiri/scripts/clam-rt.sh $@/$#

# When a file is created, opened for writing and then closed (includes modifications), or has its attributes changed
# incrond feeds the directory ($@) and filename ($#) to this script, which then scans the file with clamav
# Upon detection, a notification is sent to the user, otherwise 'no-news is good-news'

# This provides some limited real-time scanning with clamav

# Pre-flight checks
if [ ! -f "$(which clamscan)" ]; then
        printf "%s\n" "clamscan is required.  Please install it and try again."
        exit 1
elif [ ! -f "$(which incrond)" ]; then
	printf "%s\n" "incron is required.  Please install it and try again."
	exit 1
elif [ ! -f "$(which notify-send)" ]; then
        printf "%s\n" "notify-send is required.  Please install it and try again."
        exit 1
fi

# LogFile variable
LogFile=/var/log/clamav/clam-rt$(echo "${1}" | tr '/' '_')
	
# If the logfile already exists, blank it out
if [ -f "${LogFile}" ]; then
	:> "${LogFile}"
fi

# User variable, determines who to alert to
User=rawiri

# Because this is invoked as root, we need to let this script know where to notify to
#export DISPLAY=:0 #Usually this works, if not, we have to use dbus

# Sometimes this needs to be set, usually on ubuntu and derivatives
xhost +local:

# Notification function
notify (){
	ClamFault=$(grep FOUND "${LogFile}")
	export ClamFault
	Pid=$(pgrep -u ${User} pulseaudio) #Grep for a process that's likely to be there
	Dbus=$(grep -z DBUS_SESSION_BUS_ADDRESS /proc/"$Pid"/environ | sed 's/DBUS_SESSION_BUS_ADDRESS=//')
	export DBUS_SESSION_BUS_ADDRESS=$Dbus
	su ${User} -c "notify-send -u critical \"ClamAV Alert! Please investigate:\" \"${ClamFault}\""
}

# Now we scan the file and process the exit code.
clamscan -l "${LogFile}" -i "${1}"
if [ "$?" = "0" ]; then
	rm -f "${LogFile}" # We don't need these logfiles
	exit 0 # Everything's ok
else
	notify # A virus was found, so notify the user
fi
