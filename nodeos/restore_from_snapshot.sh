#!/usr/bin/env bash

SNAPSHOT=$1

TYPE="READONLY"
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

if [ ! -f "${DATA_DIR}"/snapshots/"${SNAPSHOT}" ]; then
  echo "Exiting snapshot file does not exist ${DATA_DIR}/snapshots/${SNAPSHOT}"
  exit 127
fi

if [ -f "${DATA_DIR}"/state/shared_memory.bin ]; then
  echo "ERROR MUST REMOVE ${DATA_DIR}/state/shared_memory.bin BEFORE RESTORING FROM SNAPSHOT"
  exit 1
fi

if [ "$TYPE" == "PRODUCER" ]; then
	nodeos --snapshot "${DATA_DIR}"/snapshots/"${SNAPSHOT}" --data-dir "$DATA_DIR" --wasm-runtime eos-vm --chain-state-db-size-mb 65536 --http-server-address 0.0.0.0:8888 --state-history-endpoint 0.0.0.0:8080 --agent-name "Eric Latest Nodeos" --producer-name eosio --plugin eosio::chain_api_plugin --plugin eosio::http_plugin --plugin eosio::producer_plugin --plugin eosio::state_history_plugin --plugin eosio::net_plugin --plugin eosio::producer_api_plugin --plugin eosio::net_api_plugin --disable-replay-opts --contracts-console &
else 
	nodeos --snapshot "${DATA_DIR}"/snapshots/"${SNAPSHOT}" --data-dir "$DATA_DIR" --wasm-runtime eos-vm --chain-state-db-size-mb 65536 --http-server-address 0.0.0.0:8888 --state-history-endpoint 0.0.0.0:8080 --agent-name "Eric Latest Nodeos" --plugin eosio::http_plugin --plugin eosio::state_history_plugin --plugin eosio::net_plugin --plugin eosio::net_api_plugin --disable-replay-opts --contracts-console &
fi
echo "Restored from Snapshot: now kill and restart"
