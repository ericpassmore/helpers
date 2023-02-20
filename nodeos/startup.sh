#!/bin/env bash
DIRTY=${1:-"NO"}

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

cd "${LEAP_BUILD_DIR:?}" || exit

if [ "$DIRTY" == "Y" ]; then
  nodeos --hard-replay --config-dir "$CONFIG_DIR" --data-dir "$DATA_DIR" >> "$LOG_DIR"/nodeos-eric-test.log 2>&1
else
  nodeos --config-dir "$CONFIG_DIR" --data-dir "$DATA_DIR" >> "$LOG_DIR"/nodeos-eric-test.log 2>&1
fi
