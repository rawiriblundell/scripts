#!/usr/bin/env bash

# This script was a test to see if performance could be improved on my genpasswd function
# This was for cases where a special character was required, the hope being
# that manually forcing in a special character would improve performance

# This is because genpasswd at the time of writing simply loops through password generation
# and prints out matching strings - seemingly inefficient

# Testing showed neglible difference in performance.  200 iterations of this piped into column took 12.98s,
# the same out of genpasswd took 11.359s.  Similar results were repeatable.  Tests were done on a P4.

# Replacing the shuffle method with the less portable 'shuf' resulted in similar performance

# A similar difference was found when testing on a Xeon: 5.078s for this method, 5.810s for Knuth-Fisher-Yates
# and 4.532s for the current genpasswd method

# This was written in this way in order to be portable-ish (Linux and Solaris tested)
# More elegant methods are obviously out there, I was intentionally being as basic as possible
# for the sake of simplicity and portability.

# I have added more verbose comments to this script than I normally would to make the process as clear as possible

# Declare the available special characters into an array
# Don't use '*' as a special character, it'll glob up the directory listing into your array
InputChars=(\! \@ \# \$ \% \^ \& \( \) \_ \+ \? \> \< \~)

# Generate a random character location (i.e. array index) by feeding RANDOM with the character count (#) of the array
Shuffle=$((RANDOM % ${#InputChars[@]}))

# Generate the base password to work with
Pwd=$(tr -dc '[:alnum:]' < /dev/urandom | tr -d ' ' | fold -w 10 | head -1) 2> /dev/null

# Count the chars and subtract 1
# In practice we wouldn't go through this, we'd have the fold character count as a variable, subtract 1
# and then generate $Pwd with one less character.  In other words 'fold -w 9'
((PwdLen = ${#Pwd} - 1))

# Subtract the last char from the password, insert a space between all the chars, and make an array of it
# Normally you'd use ${Pwd:: -1} but some versions of bash throw a fit about it
PwdArray=($(sed 's/.\{1\}/& /g' <<< "${Pwd:0:$PwdLen}"))

# Choose a random special character
PwdSeed=${InputChars[*]:$Shuffle:1}

# Append that special character to the password array
PwdArray+=(${PwdSeed})

# Now that the password array is built, we need to shuffle it
# Otherwise EVERY password will just have a special character on the end.

# This puts each character on a newline with a random integer, sorts on those integers
# which randomises the lines, then removes the integers and then the newlines
# which reassembles the password
for i in "${PwdArray[@]}"; do 
        printf "%s\n" "${RANDOM} ${i}"
done | sort -n | cut -d' ' -f2 | tr -d "\n"
                                
# Finally, print a cursory newline
printf "%s\n" ""
