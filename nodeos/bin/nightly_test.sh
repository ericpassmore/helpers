#!/bin/env bash

TUID=$(id -ur)

# must not be root to run
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
cd "${SPRING_BUILD_DIR:?}" || exit

TODAY=$(date -u +%F)
ctest -j "16" -LE _tests >> "$LOG_DIR"/nodeos_nightly_test_"${TODAY}".log 2>&1
ctest -j "16" -L wasm_spec_tests >> "$LOG_DIR"/nodeos_nightly_test_"${TODAY}".log 2>&1
ctest -L "nonparallelizable_tests" >> "$LOG_DIR"/nodeos_nightly_test_"${TODAY}".log 2>&1
# clean out failed tests
find /tmp -user eric -mtime +3 | xargs /bin/rm -rf
