#!/usr/bin/env bash

# See shuffletest.sh for comments

i=
tmp=
size=
max=
rand=

Pwd=$(tr -dc '[:alnum:]' < /dev/urandom | tr -d ' ' | fold -w 10 | head -1) 2> /dev/null
((PwdLen = ${#Pwd} - 1))
PwdArray=($(sed 's/.\{1\}/& /g' <<< "${Pwd:0:$PwdLen}"))
SpecialCharsArray=(\! \@ \# \$ \% \^ \& \( \) \_ \+ \? \> \< \~)
SpecialChar=$((RANDOM % ${#SpecialCharsArray[@]}))
PwdSeed=${SpecialCharsArray[*]:$SpecialChar:1}

PwdArray+=(${PwdSeed})

# $RANDOM % (i+1) is biased because of the limited range of $RANDOM
# Compensate by using a range which is a multiple of the array size.
size=${#PwdArray[*]}
max=$(( 32768 / size * size ))

for ((i=size-1; i>0; i--)); do
        while (( (rand=$RANDOM) >= max )); do :; done
        rand=$(( rand % (i+1) ))
        tmp=${PwdArray[i]} PwdArray[i]=${PwdArray[rand]} PwdArray[rand]=$tmp
done

printf "%s\n" "$(tr -d '\n' <<< ${PwdArray[@]} | tr -d ' ')"
