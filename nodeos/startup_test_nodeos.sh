#!/usr/bin/env bash

#########
# Function to start nodeos
#########
start_nodeos() {
  if [ "$1" == "PRODUCER" ]; then
  	nodeos --data-dir "$DATA_DIR" \
    --genesis-json "/tmp/genesis.json" \
    --eos-vm-oc-enable 1 \
    --chain-state-db-size-mb 200 \
    --verbose-http-errors \
    --max-transaction-time 100 \
    --http-server-address 0.0.0.0:8888 --state-history-endpoint 0.0.0.0:8080 \
    --agent-name "Test Nodeos" \
    --enable-stale-production \
    --plugin eosio::chain_api_plugin --plugin eosio::http_plugin --plugin eosio::producer_plugin --plugin eosio::net_plugin --plugin eosio::producer_api_plugin --plugin eosio::net_api_plugin \
    --disable-replay-opts --contracts-console \
    --producer-threads 2 \
    --read-only-read-window-time-us 165000 --read-only-write-window-time-us 50000 >> "$LOG_DIR"/nodeos.log 2>&1 &
  else
  	nodeos --data-dir "$DATA_DIR" \
    --genesis-json "/tmp/genesis.json" \
    --eos-vm-oc-enable 1 \
    --chain-state-db-size-mb 200 \
    --verbose-http-errors \
    --max-transaction-time 100 \
    --http-server-address 0.0.0.0:8888 --state-history-endpoint 0.0.0.0:8080 \
    --agent-name "Test Nodeos" --plugin eosio::http_plugin --plugin eosio::net_plugin --plugin eosio::net_api_plugin \
    --disable-replay-opts --contracts-console \
    --read-only-treads 4 --enable-account-queries true \
    --read-only-read-window-time-us 165000 --read-only-write-window-time-us 50000 >> "$LOG_DIR"/nodeos.log 2>&1 &
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
    exit 127
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

## Cleanup old dirs
rm -rf /bigata1/eosio/nodeos/test-data-*
rm -rf /bigata1/test-log-*

NODEOS_CONFIG=/local/eosnetworkfoundation/bin/nodeos_config.sh
if [ -f "$NODEOS_CONFIG" ]; then
  source "$NODEOS_CONFIG"
else
  echo "Cannot find ${NODEOS_CONFIG}"
  exit
fi

## Genesis File
sed "s/\"initial_timestamp\": \"YYYY-MM-DDTHH:MM:SS.000\",/\"initial_timestamp\": \"$(date -u +%FT%T.000)\",/" genesis.json > /tmp/genesis.json

cd "${LEAP_BUILD_DIR:?}" || exit

DATA_DIR=$(echo "$DATA_DIR" | sed "s#/data#/test-data-${$}#")
[ ! -d "${DATA_DIR}" ] && mkdir -p "${DATA_DIR}"
LOG_DIR=$(echo "$LOG_DIR" | sed "s#/log#/test-log-${$}#")
[ ! -d "${LOG_DIR}" ] && mkdir -p "${LOG_DIR}"

if [ -f "${DATA_DIR}"/state/shared_memory.bin ]; then
  echo "ERROR MUST REMOVE ${DATA_DIR}/state/shared_memory.bin BEFORE STARTING TEST NODEOS"
  exit 1
fi

###
start_nodeos "PRODUCER"
###

### Setup commands
if [ ! -f ~/eosio-wallet/ep-test-wallet.wallet ]; then
  cleos wallet create --name ep-test-wallet --file ~/eosio-wallet/ep-test-wallet.pw
else
  cat ~/eosio-wallet/ep-test-wallet.pw | cleos wallet unlock --name ep-test-wallet --password
fi
EOSRootPrivateKey=$(grep Private ~/eosio-wallet/ep-test-root.keys | cut -d: -f2 | sed 's/ //g')
cleos wallet import --name ep-test-wallet --private-key $EOSRootPrivateKey
EOSUserPrivateKey=$(grep Private ~/eosio-wallet/ep-test-user.keys | cut -d: -f2 | sed 's/ //g')
cleos wallet import --name ep-test-wallet --private-key $EOSUserPrivateKey
EOSUserPublicKey=$(grep Public ~/eosio-wallet/ep-test-user.keys | cut -d: -f2 | sed 's/ //g')

# boot strap
bash /local/eosnetworkfoundation/bin/reactivate_contract.sh

cleos create account eosio eosio.eptest $EOSUserPublicKey
cleos set contract eosio.eptest ./unittests/test-contracts/payloadless

###
# stop_nodeos
###
