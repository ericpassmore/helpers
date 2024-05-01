#!/usr/bin/env bash

SNAPSHOT=$1

TYPE=${2:-READONLY}
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

cd "${SPRING_BUILD_DIR:?}" || exit

if [ ! -f "${DATA_DIR}"/snapshots/"${SNAPSHOT}" ]; then
  echo "Exiting snapshot file does not exist ${DATA_DIR}/snapshots/${SNAPSHOT}"
  exit 127
fi

if [ -f "${DATA_DIR}"/state/shared_memory.bin ]; then
  echo "ERROR MUST REMOVE ${DATA_DIR}/state/shared_memory.bin BEFORE RESTORING FROM SNAPSHOT"
  exit 1
fi

if [ "$TYPE" == "PRODUCER" ]; then
	nodeos --snapshot "${DATA_DIR}"/snapshots/"${SNAPSHOT}" --data-dir "$DATA_DIR" --config "${CONFIG_DIR}"/sync-config.ini > $LOG_DIR/nodeos.log &
else
	nodeos --snapshot "${DATA_DIR}"/snapshots/"${SNAPSHOT}" --data-dir "$DATA_DIR" --config "${CONFIG_DIR}"/readonly-config.ini > $LOG_DIR/nodeos.log &
fi
echo "Restored from Snapshot: now kill and restart"
