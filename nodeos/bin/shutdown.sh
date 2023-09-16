#!/bin/env bash

set -x
TUID=$(id -ur)

# must note be root to run
if [ "$TUID" -eq 0 ]; then
  echo "Trying to run as root user exiting"
  exit
fi

NODEOS_CONFIG=/local/eosnetworkfoundation/bin/nodeos_config.sh
if [ -f "$NODEOS_CONFIG" ]; then
  source "$NODEOS_CONFIG"
else
  echo "Cannot find ${NODEOS_CONFIG}"
  exit
fi

cd ${LOG_DIR:?} || exit

USER=$(id -un)
PID=$(ps -u "$USER" | grep nodeos | sed -e 's/^[[:space:]]*//' | cut -d" " -f1)
# shutdown
if [ -n "$PID" ]; then
  kill -15 $PID
fi
# clean out old logs
find "${LOG_DIR:?}" -mtime +14 | xargs /bin/rm -rf
cp /dev/null "$LOG_DIR"/nodeos-eric-test.log
