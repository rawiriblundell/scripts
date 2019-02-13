#!/bin/env python
# A very simple python script to generate jboss/wildfly password hashes
# Requires a username, realm and password
#
# In jboss, these three are hashed as follows (from add-user.sh):
#   "
#   By default the properties realm expects the entries to be in the format: -
#   username=HEX( MD5( username ':' realm ':' password))
#   "
# This script does that, just using python
#
# No sanity checking etc is provided
# Author: Too embarrassed to put his/her name to this
# Reviewers: Please fix at your earliest convenience
# Date: 20180919

import sys, hashlib

# Rudementary help system
if len(sys.argv) != 4 :
    print('Usage: ./jboss_pwd_hash.py username realm password')
    sys.exit()

# Assign the positional parameters from 1 onwards to the variable 'triplet'
triplet = ' '.join(sys.argv[1:])

# Replace the spaces in the variable with colons
triplet = triplet.replace(" ", ":")

# md5 our variable, then hex it
md5sum = hashlib.md5(triplet).hexdigest()

# Finally, print out what we've generated
print md5sum

# The below is here for debugging/testing
#md5sum = hashlib.md5("testUserOne:ApplicationRealm:testPasswordOne").hexdigest(); print md5sum
