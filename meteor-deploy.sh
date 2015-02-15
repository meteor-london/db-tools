#!/bin/bash
#                    __
#   _____    ____  _/  |_   ____    ____  _______
#  /     \ _/ __ \ \   __\_/ __ \  /  _ \ \_  __ \
# |  Y Y  \\  ___/  |  |  \  ___/ (  <_> ) |  | \/
# |__|_|  / \___  > |__|   \___  > \____/  |__|
#      \/      \/             \/
#
#     .___
#   __| _/ __ __   _____  ______
#  / __ | |  |  \ /     \ \____ \
# / /_/ | |  |  /|  Y Y  \|  |_> >
# \____ | |____/ |__|_|  /|   __/
#      \/              \/ |__|
#

METEOR_DOMAIN="$1"
DUMP_DIR="${2:-dump}"

if [[ "$METEOR_DOMAIN" == "" ]]
then
  echo "You need to supply your meteor app name and the path to the dump dir"
  echo "e.g. ./meteor-deploy.sh app <path>"
  exit 1
fi

./meteor-dump.sh "$1" "$DUMP_DIR"
if [[ "$?" == "1" ]]
then
  echo "meteor-dump.sh failed. Please try to execute it directly."
  echo "e.g. ./meteor-dump.sh $METEOR_DOMAIN $DUMP_DIR"
  exit 1
fi

meteor deploy "$1"

./meteor-restore.sh "$1" "$DUMP_DIR"
if [[ "$?" == "1" ]]
then
  echo "meteor-restore.sh failed. Please try to execute it directly."
  echo "e.g. ./meteor-restore.sh $METEOR_DOMAIN $DUMP_DIR"
  exit 1
fi

exit 0
