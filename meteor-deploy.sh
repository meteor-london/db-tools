#!/bin/bash


################################################################################
#
# Name        : Meteor app deployer
# Version     : 1.0.0
# Last edit   : 22/02/2015
# Description : Building and deploying a meteor app onto a unix server
#               through SSH
# Author(s)   : Grabcode (@grabthecode)
#
# Exit codes  :
#   0 : No error
#   1 : Missing mandatory parameter
#
################################################################################

### Functions declaration

# Usage info
show_help() {
cat << EOF
Usage: ${0##*/} --ssh username@hostname --app app_name [-v] [-r remote_user]
Deploy meteor app to given host.
    -a | --app  meteor application name
    -s | --ssh  remote server ssh connection details
    -r          remote user name launching the app
    -u          remote upstart service managing the meteor app
    -h | --help pring usage
    -v          verbose mode
EOF
}

if [ $# -eq 0 ]; then
  show_help
  exit 1
fi

# Log helper
log() {
  echo "`date` :: $1" >&2
}

# Param parsing helper
process_arg (){
  if [ "$1" != '' ]; then
    echo $1
  else
    log 'ERROR: Must specify a non-empty argument.'
    exit 1
  fi
}

# Parsing parameters
while [ "$#" -gt 0 ]; do
  case $1 in
      -h|-\?|--help)   # Call a "show_help" function to display a synopsis, then exit.
        show_help
        exit
        ;;
      -a|--app)
        APP=$(process_arg $2)
        if [ $? -ne 0 ]; then
          exit 1
        fi
        shift 2
        continue
        ;;
      -s|--ssh)
        HOST=$(process_arg $2)
        if [ $? -ne 0 ]; then
          exit 1
        fi
        shift 2
        continue
        ;;
      -r)
        REMOTE_USER=$(process_arg $2)
        if [ $? -ne 0 ]; then
          exit 1
        fi
        shift 2
        continue
        ;;
      -u)
        REMOTE_SERVICE=$(process_arg $2)
        if [ $? -ne 0 ]; then
          exit 1
        fi
        shift 2
        continue
        ;;
      -v)
        VERBOSE="${i#*=}"
        ;;
      --)              # End of all options.
        shift
        break
        ;;
      -?*)
        log 'WARN: Unknown option (ignored): %s\n' "$1" >&2
        ;;
      *)               # Default case: If no more options then break out of the loop.
        break
  esac

  shift
done

# Check mandatory parameters
if [ ! "$APP" ] || [ ! "$HOST" ]; then
  log 'ERROR: missing mandatory parameter. See --help.' >&2
  exit 1
fi

APP_TAR="$APP".tar.gz

#Default REMOTE_USER to APP
if [ ! "$REMOTE_USER" ]; then
  REMOTE_USER="$APP"
fi
REMOTE_USERHOME=/home/"$REMOTE_USER"

#Default REMOTE_SERVICE to APP
if [ ! "$REMOTE_SERVICE" ]; then
  REMOTE_SERVICE="$APP"
fi


### Variables definition
log " *** Settings ***"
log "APP             [$APP]"
log "HOST            [$HOST]"
log "REMOTE_USER     [$REMOTE_USER]"
log "REMOTE_USERHOME [$REMOTE_USERHOME]"
log "REMOTE_SERVICE  [$REMOTE_SERVICE]"


#todo: warning if branch is not master, if git detected
log " *** STARTING DEPLOYMENT ***"

# todo: add git tags
#Valid architectures include os.osx.x86_64, os.linux.x86_64, and os.linux.x86_32.
log "Building $APP"
meteor build . --architecture os.linux.x86_64 #todo: get architecture based on uname
log "Uploading $APP_TAR to $HOST"
scp $APP_TAR $HOST:~
log "Removing $APP_TAR"
rm $APP_TAR


### Remote commands - assumptions: upstart service named "$APP"
log "Connection to $HOST"
ssh -T $HOST <<EOF
$(typeset -f) #getting log defined

log "Moving $APP_TAR to $REMOTE_USERHOME"
sudo mv $APP_TAR $REMOTE_USERHOME

log "Transferring permissions to $REMOTE_USER"
sudo chown $REMOTE_USER:$REMOTE_USER $REMOTE_USERHOME -R

log "Log in as $REMOTE_USER"
sudo su $REMOTE_USER

$(typeset -f) #getting log defined

log "Unpacking $APP_TAR"
cd $REMOTE_USERHOME
tar -zxf $APP_TAR
rm $APP_TAR

log "Installing dependancies"
cd bundle/programs/server/
npm install

log "Logout from $REMOTE_USER"
exit

log "Restarting upstart service $APP"
sudo service $APP restart
exit

EOF
log "Closing ssh connection"

log " *** DEPLOYMENT OVER ***"
exit 0
