#! /usr/bin/env sh

PERIOD=${1:-60}
DEST=${WEBDRIVE_MOUNT:-/mnt/webdrive}

. trap.sh

while true; do
    ls -al $DEST
    sleep $PERIOD
done
