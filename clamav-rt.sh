#!/usr/bin/env bash

# Released under the WTFPL public license 
# http://www.wtfpl.net/

# Author: Rawiri Blundell, 09/2014

# A limited real-time AV script that's called by incrond.  Create the file /etc/incron.d/clamav with the contents:
# [Directory to watch] IN_CLOSE_WRITE,IN_ATTRIB,IN_MODIFY,IN_MOVED_TO /path/to/clam-rt.sh $@/$#
# e.g.
# /home/rawiri/Downloads IN_CLOSE_WRITE,IN_ATTRIB,IN_MODIFY,IN_MOVED_TO /home/rawiri/scripts/clam-rt.sh $@/$#

# When a file is created in, modified in or moved to the directory being watched
# incrond feeds the directory ($@) and filename ($#) to this script, which then scans the file with clamav
# Upon detection, a notification is sent to the user, otherwise 'no-news is good-news'

# First we need to tell the script who to alert to.  This could be built smarter
User=rawiri

# Next let's set the notify function
notify (){
        # Because this is invoked as root, we need to let this script know where to notify to
        #export DISPLAY=:0 #Usually this works, if not, we have to use dbus

        # Sometimes this needs to be set, usually on ubuntu and derivatives
        xhost +local:

        Pid=$(pgrep -u ${User} pulseaudio) #Grep for a process that's likely to be there
        Dbus=$(grep -z DBUS_SESSION_BUS_ADDRESS /proc/"$Pid"/environ | sed 's/DBUS_SESSION_BUS_ADDRESS=//')
        export DBUS_SESSION_BUS_ADDRESS=$Dbus
        su ${User} -c "notify-send -u critical \"ClamAV-RT Alert! Please investigate:\" \"${ClamFault}\""
}

# Pre-flight checks.  Check dependencies
Dependencies="clamscan incrond notify-send"
for d in ${Dependencies}; do
	if [[ ! "$(which "${d}")" > /dev/null ]]; then
		ClamFault="${d} is required.  Please install it and try again."
		notify #Notify the user which dependency is missing
        	printf "%s\n" "$d is required.  Please install it and try again."
        	exit 1
        fi
done

# LogFile variable
LogFile=/var/log/clamav/clam-rt$(echo "${1}" | tr '/' '_')
	
# If the logfile already exists, blank it out
if [ -f "${LogFile}" ]; then
	:> "${LogFile}"
fi

# Now we scan the file and process the exit code.
clamscan -l "${LogFile}" -i "${1}"
if [ "$?" = "0" ]; then
	rm -f "${LogFile}" #We don't need these logfiles
	exit 0 #Everything's ok
else
	ClamFault=$(grep FOUND "${LogFile}") #Get the FOUND line from the logfile
	notify #A virus was found, so notify the user
fi
