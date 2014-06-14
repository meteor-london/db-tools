#!/bin/bash
#                    __
#   _____    ____  _/  |_   ____    ____  _______
#  /     \ _/ __ \ \   __\_/ __ \  /  _ \ \_  __ \
# |  Y Y  \\  ___/  |  |  \  ___/ (  <_> ) |  | \/
# |__|_|  / \___  > |__|   \___  > \____/  |__|
#      \/      \/             \/
#
#                          __
# _______   ____    _______/  |_   ____  _______   ____
# \_  __ \_/ __ \  /  ___/\   __\ /  _ \ \_  __ \_/ __ \
#  |  | \/\  ___/  \___ \  |  |  (  <_> ) |  | \/\  ___/
#  |__|    \___  >/____  > |__|   \____/  |__|    \___  >
#              \/      \/                             \/
#
# The meteor.com Hot Dump 2-step
# Restore a mongo db from a local dump dir to an app hosted on meteor.com
#
# Splits up the output of:
#    meteor mongo $METEOR_DOMAIN --url
# and pushes it into
#    mongorestore -u $MONGO_USER -h $MONGO_DOMAIN -d $MONGO_DB -p "${MONGO_PASSWORD}"
#
# Doing so by hand is tedious as the password in the url is only valid for 60 seconds.
#
# As per the monogorestore docs:
#
# - mongorestore recreates indexes recorded by mongodump.
# - all operations are inserts, not updates.
# - mongorestore does not wait for a response from a mongod to ensure that the MongoDB process has received or recorded the operation.
# - The mongod will record any errors to its log that occur during a restore operation, but mongorestore will not receive errors.
#
# Requires
# - meteor  (tested on 0.8.1)
# - mongodb (tested in 2.4.0)
#
# Usage
#    ./meteor-restore.sh goto
#
# By @olizilla
# On 2013-03-20. Using this script after it's sell by date may void your warranty.
#

METEOR_DOMAIN="$1"
DUMP_DIR="${2:-dump}"

if [[ "$METEOR_DOMAIN" == "" ]]
then
	echo "You need to supply your meteor app name and the path to the dump dir"
	echo "e.g. ./meteor-restore.sh app <path>"
	exit 1
fi

# REGEX ALL THE THINGS.
# Chomps the goodness flakes out of urls like "mongodb://client:pass-word@skybreak.member0.mongolayer.com:27017/goto_meteor_com"
MONGO_URL_REGEX="mongodb:\/\/(.*):(.*)@(.*)\/(.*)"

# stupid tmp file as meteor may want to prompt for a password
TMP_FILE="/tmp/meteor-restore.tmp"

# Get the mongo url for your meteor app
meteor mongo $METEOR_DOMAIN --url | tee "${TMP_FILE}"

MONGO_URL=$(sed '/Password:/d' "${TMP_FILE}")

# clean up the temp file
if [[ -f "${TMP_FILE}" ]]
then
	rm "${TMP_FILE}"
fi

if [[ $MONGO_URL =~ $MONGO_URL_REGEX ]]
then
	MONGO_USER="${BASH_REMATCH[1]}"
	MONGO_PASSWORD="${BASH_REMATCH[2]}"
	MONGO_DOMAIN="${BASH_REMATCH[3]}"
	MONGO_DB="${BASH_REMATCH[4]}"

	#e.g mongorestore -u client -h skybreak.member0.mongolayer.com:27017 -d goto_meteor_com -p "guid-style-password" ~/dump
	mongorestore -u $MONGO_USER -h $MONGO_DOMAIN -d $MONGO_DB -p "${MONGO_PASSWORD}" $DUMP_DIR
else
	echo "Sorry, no restore for you. Couldn't extract your details from the url: ${MONGO_URL}"
	exit 1
fi
