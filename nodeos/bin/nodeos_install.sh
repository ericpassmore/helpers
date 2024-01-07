#!/bin/env bash

TUID=$(id -ur)

# must be root to run
if [ "$TUID" -ne 0 ]; then
  echo "Not root user exiting"
  exit
fi

NODEOS_CONFIG=/local/eosnetworkfoundation/bin/nodeos_config.sh
if [ -f "$NODEOS_CONFIG" ]; then
  source "$NODEOS_CONFIG"
else
  echo "Cannot find ${NODEOS_CONFIG}"
  exit
fi
cd "${LEAP_BUILD_DIR:?}"/packages/ || exit

DEBIAN_FRONTEND=noninteractive
export DEBIAN_FRONTEND
apt-get remove -y leap >> "$LOG_DIR"/nodeos_nightly_install_"${TODAY}".log 2>&1
apt-get update >> "$LOG_DIR"/nodeos_nightly_install_"${TODAY}".log 2>&1
apt-get install -y ./leap[-_][0-9]*.deb >> "$LOG_DIR"/nodeos_nightly_install_"${TODAY}".log 2>&1
