#!/usr/bin/env bash

#########
# Function to start nodeos
#########
start_nodeos() {
  if [ "$1" == "PRODUCER" ]; then
  	nodeos --data-dir "$DATA_DIR" \
    --eos-vm-oc-enable 1 \
    --chain-state-db-size-mb 200 \
    --http-server-address 0.0.0.0:8888 --state-history-endpoint 0.0.0.0:8080 \
    --agent-name "Test Nodeos" --producer-name eosio \
    --plugin eosio::chain_api_plugin --plugin eosio::http_plugin --plugin eosio::producer_plugin --plugin eosio::state_history_plugin --plugin eosio::net_plugin --plugin eosio::producer_api_plugin --plugin eosio::net_api_plugin \
    --disable-replay-opts --contracts-console \
    --read-only-read-window-time-us = 165000 >> "$LOG_DIR"/nodeos.log 2>&1
  else
  	nodeos --data-dir "$DATA_DIR" \
    --eos-vm-oc-enable 1 \
    --chain-state-db-size-mb 200 \
    --http-server-address 0.0.0.0:8888 --state-history-endpoint 0.0.0.0:8080 \
    --agent-name "Test Nodeos" --plugin eosio::http_plugin --plugin eosio::state_history_plugin --plugin eosio::net_plugin --plugin eosio::net_api_plugin \
    --disable-replay-opts --contracts-console \
    --read-only-treads 4 --read-only-read-window-time-us 165000 >> "$LOG_DIR"/nodeos.log 2>&1
  fi

  echo "Started Nodeos"
  sleep 1
  USER=$(id -un)
  PID=$(ps -u "$USER" | grep nodeos | sed -e 's/^[[:space:]]*//' | cut -d" " -f1)
  # Check for running nodeos; if not running cat out log
  if [ -z "$PID" ]; then
    cat "$LOG_DIR"/nodeos.log
    echo "**********************"
    echo "   FAILED TO START    "
  fi
}

#########
# Function to stop nodeos
#########
stop_nodeos() {
  echo "Stopping Nodeos"
  sleep 1
  USER=$(id -un)
  PID=$(ps -u "$USER" | grep nodeos | sed -e 's/^[[:space:]]*//' | cut -d" " -f1)
  # Stop oldest process
  if [ -n "$PID" ]; then
    kill -15 $PID
  fi
}


NODEOS_CONFIG=/local/eosnetworkfoundation/bin/nodeos_config.sh
if [ -f "$NODEOS_CONFIG" ]; then
  source "$NODEOS_CONFIG"
else
  echo "Cannot find ${NODEOS_CONFIG}"
  exit
fi

cd "${LEAP_BUILD_DIR:?}" || exit

DATA_DIR=$(echo "$DATA_DIR" | sed "s#/data#/test-data-${$}#")
[ ! -d "${DATA_DIR}" ] && make -p "${DATA_DIR}"
LOG_DIR=$(echo "$LOG_DIR" | sed "s#/log#/test-data-${$}#")
[ ! -d "${LOG_DIR}" ] && make -p "${LOG_DIR}"

if [ -f "${DATA_DIR}"/state/shared_memory.bin ]; then
  echo "ERROR MUST REMOVE ${DATA_DIR}/state/shared_memory.bin BEFORE STARTING TEST NODEOS"
  exit 1
fi

###
start_nodeos "PRODUCER"
###

### Setup commands
cleos wallet open --file "$DATA_DIR"/wallet.pw
cat "$DATA_DIR"/wallet.pw | cleos wallet unlock --password
cleos wallet import --private-key 5KQwrPbwdL6PhXujxW37FSSQZ1JiwsST4cqQzDeyXtP79zkvFD3
cleos create account eosio eosio.eptest EOS7K8xh4J5tWD5oUSvMAJW7UwgcsMoR4K3f8cpL5gvZ8udV7v51a
cleos set contract doit ./unittests/test-contracts/payloadless -p eosio.eptest@owner

###
stop_nodeos
###
