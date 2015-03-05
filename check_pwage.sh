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
#		made wrappable for batch auditing, passed shellcheck.net.  
# 07/10/2014 - Heavier changes, improved readability, added getopts, enabled email switching and verbose mode
# 18/12/2014 - Minor adjustment to allow NRPE compatibility
# 03/02/2015 - Added MaxAge defaulting code to cater for blank fields
# 05/03/2015 - Some portability fixes after testing on Solaris

# TO DO
# =========================================================================
# Build in chage support.  At the moment this is portable-ish, 
#   but if chage is available, it makes sense to use it.

# VARIABLES
# =========================================================================
Log=/tmp/${0##*/}.$(date +%Y%m%d).log
Host="$(uname -n)"
Dashes="-----------------------------"

# Set the default email address
# This is essentially a dummy variable as $Email needs to be true for it to be used
# It's intended that one day '-e' alone will default to this and '-e some@email.address' behaves too.
EmailAddr=sysadmins@somecompany.tld

# Set the default exit code
ExitCode=0

# Set the default variables for getopts
Passwd=/etc/passwd
Shadow=/etc/shadow
Email="false"
User=""
Verbose="false"

# FUNCTIONS
# =========================================================================
Show() {
    printf "%s\n" "${Dashes} ${1} ${Dashes}" >> "${Log}"
    shift
    printf "%s\n" "$(eval "$@")" "" >> "${Log}"
}

Usage () {
	printf "%s\n" " Usage: ${0##*/} -u User [-e [Email] -p [passwd file] -s [shadow file] -h -v]" "" \
	" Options:" \
	"	-u User account to check." \
        "	-e Enable email.  You must supply an email address i.e. '-e example@example.com'" \
	"	-p Path to optional passwd file.  Useful for auditing collected files." \
	"	-s Path to optional shadow file.  Useful for auditing collected files." \
	"	-h Help.  What you're looking at." \
	"	-v Verbose.  Enables extra output on stdout."
}

Scriptargs() {
	echo Date: "$(date)"
	echo System: "$(uname -a)"
}

SendMail() {
	mailx -s "${1}" "${EmailAddr}" < "${Log}"
}

Reminder () {
	printf "%s\n" "Date: $(date)" "" "${User} needs to change their password within the next ${Expire} days."
}

Expired () {
	printf "%s\n" "Date: $(date)" "" \
	"The password for ${User} has expired." \
	"The user: '${User}' last changed their password on ${LastChange}" \
	"The maximum age for the password is ${MaxAge} days" \
	"and it has expired ${Expire} days ago."
}

Verbose () {
        printf "%s\n" "Detail for ${User}'s password:" "Password expires in ${Expire} days." \
        "${User} last changed their password on ${LastChange}." \
        "${User}'s password is ${AgeToday} days old." \
        "Maximum Password Age: ${MaxAge} days." \
        "Warning Period: ${WarnTime} days."
}

# GETOPTS
# =========================================================================
while getopts ":e:hp:s:u:v" Flags; do
	case "${Flags}" in
		e)	Email="true";
			EmailAddr="${OPTARG}";;
		h)	Usage
			exit 0;;
		p)	Passwd="${OPTARG}";;
		s)	Shadow="${OPTARG}";;	
		u)	User="${OPTARG}";;
		v)	Verbose="true";;
		\?)	printf "%s\n" "ERROR: Invalid option: $OPTARG.  Try '${0##*/} -h' for usage." >&2
			exit 1;;
		:)	printf "%s\n" "ERROR: Option '-${OPTARG}' requires an argument." >&2 
			exit 1;;
	esac
done

# PREFLIGHT CHECKS
# =========================================================================
# Blank the logfile
:> "${Log}"

# Are we root?
if [[ $EUID -ne 0 ]]; then
	printf "%s\n" "This script must be run as root.  Try 'sudo ./${0##*/}'." 1>&2
	exit 1
fi

# Now check that the user variable is not blank.
# Without this check, the script breaks severely.
if [ "${User}" = ""  ]; then
	printf "%s\n" "I require a username to work against.  The -u' argument is blank." \
	"Please try './${0##*/} -u USERNAME', or use './${0##*/} -h' for usage."
	cat "${Log}"
		if [ "${Email}" = "true" ]; then
			SendMail "Blank user optarg for command ${0##*/} on ${Host}"
        	fi
        :> "${Log}"
        exit 1
fi

# Now we check that the user exists in the passwd file
if ! grep -q "${User}" "${Passwd}"; then
        printf "%s\n" "${User} not found in ${Passwd}."
        if [ "${Email}" = "true" ]; then
                SendMail "${User} not found in ${Passwd} error from command ${0##*/} on ${Host}"
        fi
        :> "${Log}"
        exit 1
fi

# PROCESSING AND OUTPUT
# =========================================================================
# Processing variables, must be post-checks
Changed="$(grep -w "${User}" "${Shadow}" | cut -d: -f3)"
MaxAge="$(grep -w "${User}" "${Shadow}" | cut -d: -f5)"
WarnTime="$(grep -w "${User}" "${Shadow}" | cut -d: -f6)"

# Find the epoch time since the user's password was last changed
DaysNow="$(perl -e 'print int(time/(60*60*24))')"
((Change = Changed + 1))
DateChange="$(perl -e 'print scalar localtime('$Change' * 24 * 3600);')"
LastChange="$(printf "%s" "${DateChange}" | cut -d' ' -f1-4)"

# If the password change field is blank, let's log that
if [[ "${Changed}" = "" ]]; then
	Changed=0
	printf "%s\n" "${0##*/} - Auditing account: ${User} in ${Passwd}.  No date for last change of password found, defaulting to 0." >> "${Log}"
fi

# If the password WarnTime field is blank, let's default it
if [[ "${WarnTime}" = "" ]]; then
	WarnTime=7
	printf "%s\n" "${0##*/} - Auditing account: ${User} in ${Passwd}.  No Warn time found, using default of 7 days." >> "${Log}"
fi

# If the password MaxAge field is blank, let's default it
if [[ "${MaxAge}" = "" ]]; then
	MaxAge=30
	printf "%s\n" "${0##*/} - Auditing account: ${User} in ${Passwd}.  No Max password age found, using default of 30 days." >> "${Log}"
fi

# Compute the age of the user's password
if [ "${DaysNow}" -ge "${Changed}" ]; then
	((AgeToday = DaysNow - Changed))
else
	# This has happened, so we'll take care of this condition
	printf "%s\n" "${User} changed password date is in the future!!!" >> "${Log}"
fi
	
# If the MaxAge field is greater than the password's age, there's still some juice
if [[ ${MaxAge} -ge ${AgeToday} ]]; then
	# So we figure out just how much juice is left
	((Expire = MaxAge - AgeToday))
	
	# So if the password is inside the warning period, it's time to alert
	if [[ ${WarnTime} -ge ${Expire} ]]; then
		Show "R E M I N D E R" Reminder
		if [ "${Email}" = "true" ]; then
			SendMail "WARNING: Password Info for ${User} On ${Host}"
		fi
		ExitCode=1
	fi

# Otherwise, the password has expired.
else
        # So we figure out just how much it has expired by
        ((Expire = MaxAge - AgeToday))
	
	Show "E X P I R E D" Expired
	if [ "${Email}" = "true" ]; then
		SendMail "ALERT: ${User}'s Password Expired On ${Host}"
	fi
	ExitCode=2
fi

# If the Verbose flag is set, we print out some more info
if [ "${Verbose}" = "true" ]; then
	if [ "${Email}" = "true" ]; then
		Verbose > "${Log}"
		SendMail "Password Info for ${User} On ${Host}"
	else
		Verbose
	fi
fi

# Finally clean up and exit
:> "${Log}"
exit "${ExitCode}"
