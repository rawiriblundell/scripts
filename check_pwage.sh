#!/usr/bin/env bash

# Purpose:
# This script works out the time left before a password expires
# and notifies based on what it finds.  It is intended for sysadmin auditing
# (e.g. cron check root password) not user warnings.  Though it could be modified for that.

# Author: Rawiri Blundell
# Based heavily on the pwcheck script by Goran Cvetanoski - 19/12/2006
# Sourced from http://www.unix.com/shell-programming-and-scripting/33854-check-password-age.html

# Usage: see check_pwage.sh -h

# CHANGE LOG
# =========================================================================
# 06/10/2014 - Bashified, modernised.  Heavy changes, improved logic, 
#				made wrappable for batch auditing, passed shellcheck.net.  
# 07/10/2014 - Heavier changes, improved readability, added getopts, enabled email switching and verbose mode

# VARIABLES
# =========================================================================
Log=/tmp/${0##*/}.$(date +%Y%m%d).log
Host="$(uname -n)"
Dashes="-----------------------------"

# Set the default email address, can be a comma separated list
Recipient=sysadmins@somecompany.tld

# Set the default variables for getopts
Passwd=/etc/passwd
Shadow=/etc/shadow
Email="false"
EmailAddr=""
User=""
Verbose="false"

# FUNCTIONS
# =========================================================================
show() {
    printf "%s\n" "${Dashes} ${1} ${Dashes}" >> "${Log}"
    shift
    printf "%s\n" "$(eval "$@")" "" >> "${Log}"
}

usage () {
	printf "%s\n" " Usage: ${0##*/} -u User [-e [Email] -p [passwd file] -s [shadow file] -h -v]" "" \
	" Options:" \
	"	-u User to check against." \
	"	-e Enable email.  If you invoke this without an email address, ${Recipient} is used." \
	"	-p Path to optional passwd file.  Useful for auditing collected files." \
	"	-s Path to optional shadow file.  Useful for auditing collected files." \
	"	-h Help.  What you're looking at." \
	"	-v Verbose.  Enables extra output on stdout."
}

scriptargs() {
	echo Date: "$(date)"
	echo System: "$(uname -a)"
}

SendMail() {
	mailx -s "${1}" "${Notify}" < "${Log}"
}

reminder () {
	printf "%s\n" "Date: $(date)" "" "${User} needs to change their password within the next ${Expire} days."
}

expired () {
	printf "%s\n" "Date: $(date)" "" \
	"The password for ${User} has expired" \
	"${User} last changed their password on ${LastChange}" \
	"The maximum age for the password is ${MaxAge} days" \
	"and it has expired ${Expire} days ago."
}

# GETOPTS
# =========================================================================
while getopts "ehp:s:u:v" Flags; do
	case "${Flags}" in
		e)	Email="true";
			EmailAddr="${OPTARG}";;
		h)	usage
			exit 0;;
		p)	Passwd="${OPTARG}";;
		s)	Shadow="${OPTARG}";;	
		u)	User="${OPTARG}";;
		v)	Verbose="true";;
		\?)	printf "%s\n" "ERROR: Invalid option: $OPTARG.  Try '${0##*/} -h' for usage." >&2
			exit 1;;
		:)	printf "%s\n" "Option '-$OPTARG' requires an argument, e.g. '-$OPTARG /some/path/to/etc/passwd'." >&2
			exit 1;;
	esac
done

# PREFLIGHT CHECKS
# =========================================================================
# Blank the logfile
:> "${Log}"

# Check arguments.  First we sort out the email address
if [ "${Email}" = "true" ]; then
        if [ "${EmailAddr}" = "" ]; then
                Notify=${Recipient}
        else
                Notify=${EmailAddr}
        fi
fi

# Next we check that the user variable is not blank
# This is perhaps the most important check, without this, the script breaks
if [ "${User}" = ""  ]; then
	printf "%s\n" "I require a username to work against.  The User argument is blank." \
	"Please try '${0##*/} -u USERNAME', or use '${0##*/} -h' for usage."
	cat "${Log}"
		if [ "${Email}" = "true" ]; then
			Notify=${Recipient}
			SendMail "Blank user argv for command ${0##*/} on ${Host}"
        	fi
        :> "${Log}"
        exit 1
fi

# Now we check that the user exists in the passwd file
if ! grep -q "${User}" "${Passwd}"; then
	printf "%s\n" "${User} not found in ${Passwd}."
	if [ "${Email}" = "true" ]; then
		Notify=${Recipient}
		SendMail "User not found error from command ${0##*/} on ${Host}"
      	fi
        :> "${Log}"
        exit 1
fi

# PROCESSING AND OUTPUT
# =========================================================================
# Processing variables, must be post-checks
Changed="$(grep "${User}" "${Shadow}" | cut -d: -f3)"
MaxAge="$(grep "${User}" "${Shadow}" | cut -d: -f5)"
WarnTime="$(grep "${User}" "${Shadow}" | cut -d: -f6)"

# Find the epoch time since the user's password was last changed
DaysNow="$(perl -e 'print int(time/(60*60*24))')"
((Change = Changed + 1))
LastChange="$(perl -e 'print scalar localtime('$Change' * 24 *3600);')"

# If the password change field is blank, let's log that
if [ "${Changed}" = "" ]; then
	Changed=0
	printf "%s\n" "${0##*/} - ${User} on ${Host} has no date for change of password" >> "${Log}"
fi

# Compute the age of the user's password
if [ "${DaysNow}" -ge "${Changed}" ]; then
	((AgeToday = DaysNow - Changed))
else
	# This has happened, so we'll take care of this condition
	printf "%s\n" "${User} changed password date is in the future!!!" >> "${Log}"
fi
	
# If the MaxAge field is greater than the password's age, there's still some juice
if [ "${MaxAge}" -ge ${AgeToday} ]; then
	# So we figure out just how much juice is left
	((Expire = MaxAge - AgeToday))
	# So if the password is inside the warning period, it's time to alert
	if [ "${WarnTime}" -ge ${Expire} ]; then
		show "R E M I N D E R" reminder
		if [ "${Email}" = "true" ]; then
			SendMail "${User} Password Info On ${Host}"
		fi
	fi
# Otherwise, the password has expired.
else
	show "E X P I R E D" expired
	if [ "${Email}" = "true" ]; then
		SendMail "WARNING: ${User} Password Expired On ${Host}"
	fi
fi

# If the Verbose flag is set, we print out some more info
if [ "${Verbose}" = "true" ]; then
	printf "%s\n" "Detail for ${User}'s password:" "Password expires in ${Expire} days." \
	"${User} last changed their password on ${LastChange}." \
	"${User}'s password is ${AgeToday} days old." \
	"Maximum Password Age: ${MaxAge} days." \
	"Warning Period: ${WarnTime} days."
fi

# Finally clean up and exit
:> "${Log}"
exit 0
