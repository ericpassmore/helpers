#!/bin/env bash

TODAY=$(date -u +%F)

NODEOS_CONFIG=/local/eosnetworkfoundation/bin/nodeos_config.sh
if [ -f "$NODEOS_CONFIG" ]; then
  source "$NODEOS_CONFIG"
else
  echo "Cannot find ${NODEOS_CONFIG}"
  exit
fi

USER=$(id -un)
CHECK=$(ps -u "$USER" | grep nodeos)
if [ -z "$CHECK" ]; then
  echo "**** ERROR NODEOS NOT RUNNING"
else
  echo "**** NODES OK"
fi
if [ -f "$LOG_DIR"/nodeos_nightly_test_"${TODAY}".log ]; then
  echo "**** CHECK TEST LOGS"
  grep fail "$LOG_DIR"/nodeos_nightly_test_"${TODAY}".log
else
  echo "**** No Test Logs for ${TODAY}"
fi
echo "**** LIB BLOCK IDS"
curl -s -X POST http://127.0.0.1:8888/v1/chain/get_info | cut -d, -f4
sleep 2
curl -s -X POST http://127.0.0.1:8888/v1/chain/get_info | cut -d, -f4
sleep 2
curl -s -X POST http://127.0.0.1:8888/v1/chain/get_info | cut -d, -f4
sleep 2
