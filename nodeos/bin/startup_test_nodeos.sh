#!/usr/bin/env bash

#########
# Function to start nodeos
#########
start_nodeos() {
  ## Create Config with Production Keys
  if [ "$1" == "PRODUCER" ]; then
    sed "s/EOSRootPublicKey/$EOSRootPublicKey/" "${ROOT_DIR}"/bin/config/test-producer-config.ini \
       | sed "s/EOSRootPrivateKey/$EOSRootPrivateKey/" > "${CONFIG_DIR}"/config.ini
  fi
  if [ "$1" == "READONLY" ]; then
    sed "s/EOSRootPublicKey/$EOSRootPublicKey/" "${ROOT_DIR}"/bin/config/test-readonly-config.ini \
       | sed "s/EOSRootPrivateKey/$EOSRootPrivateKey/" > "${CONFIG_DIR}"/config.ini
  fi
  ## Startup
  nodeos --data-dir "$DATA_DIR" --config-dir "$CONFIG_DIR" >> "$LOG_DIR"/nodeos.log 2>&1 &
  echo "Started $1 Nodeos with $DATA_DIR and $CONFIG_DIR"
  sleep 1

  USER=$(id -un)
  PID=$(ps -u "$USER" | grep nodeos | sed -e 's/^[[:space:]]*//' | cut -d" " -f1)
  # Check for running nodeos; if not running cat out log
  if [ -z "$PID" ]; then
    if [ -f "$LOG_DIR"/nodeos.log ]; then
      cat "$LOG_DIR"/nodeos.log
    else
      echo "NO FILE FILE AT $LOG_DIR/nodeos.log"
    fi
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

## Source Config, provides the following:
# ROOT_DIR
# LEAP_GIT_DIR
# LEAP_BUILD_DIR
# TEMPLATE_DIR
# NODEOS_RUN_DIR
# CONFIG_DIR
# DATA_DIR
# LOG_ROOT_DIR
# LOG_DIR
# WALLET_DIR
NODEOS_CONFIG=/local/eosnetworkfoundation/bin/nodeos_config.sh
if [ -f "$NODEOS_CONFIG" ]; then
  source "$NODEOS_CONFIG"
else
  echo "Cannot find ${NODEOS_CONFIG}"
  exit
fi

## Cleanup old dirs
rm -rf "${NODEOS_RUN_DIR}"/test-data-*
rm -rf "${NODEOS_RUN_DIR}"/test-config-*
rm -rf "${LOG_ROOT_DIR}"/test-log-*

# for saftey and access to contracts drop here
cd "${LEAP_BUILD_DIR:?}" || exit

## Set test directory names DATA , LOG, CONFIG
DATA_DIR=$(echo "$DATA_DIR" | sed "s#/data#/test-data-${$}#")
[ ! -d "${DATA_DIR}" ] && mkdir -p "${DATA_DIR}"
LOG_DIR=$(echo "$LOG_DIR" | sed "s#/log#/test-log-${$}#")
[ ! -d "${LOG_DIR}" ] && mkdir -p "${LOG_DIR}"
CONFIG_DIR=$(echo "$CONFIG_DIR" | sed "s#/config#/test-config-${$}#")
[ ! -d "${CONFIG_DIR}" ] && mkdir -p "${CONFIG_DIR}"

## Check not existing dir
if [ -f "${DATA_DIR}"/state/shared_memory.bin ]; then
  echo "ERROR MUST REMOVE ${DATA_DIR}/state/shared_memory.bin BEFORE STARTING TEST NODEOS"
  exit 1
fi

## Get EOS ROOT KEYS
EOSRootPrivateKey=$(grep Private "${WALLET_DIR}"/ep-test-root.keys | cut -d: -f2 | sed 's/ //g')
EOSRootPublicKey=$(grep Public "${WALLET_DIR}"/ep-test-root.keys | cut -d: -f2 | sed 's/ //g')

###
start_nodeos "PRODUCER"
###

### Setup commands
# Open/Unlock Wallet
# Add Private Keys if needed
if [ ! -f "${WALLET_DIR}"/ep-test-wallet.wallet ]; then
  cleos wallet create --name ep-test-wallet --file "${WALLET_DIR}"/ep-test-wallet.pw
fi
IS_WALLET_OPEN=$(cleos wallet list | grep ep-test-wallet | grep -F '*' | wc -l)
# not open then it is locked so unlock it
if [ $IS_WALLET_OPEN -lt 1 ]; then
  cat "${WALLET_DIR}"/ep-test-wallet.pw | cleos wallet unlock --name ep-test-wallet --password
fi
# Import Root Private Key
ROOT_KEY_SEARCH=$(cleos wallet keys | grep "$EOSRootPublicKey" | wc -l)
if [ $ROOT_KEY_SEARCH -lt 1 ]; then
  cleos wallet import --name ep-test-wallet --private-key $EOSRootPrivateKey
fi
# Import User Private Key
EOSUserPublicKey=$(grep Public "${WALLET_DIR}"/ep-test-user.keys | cut -d: -f2 | sed 's/ //g')
EOSUserPrivateKey=$(grep Private "${WALLET_DIR}"/ep-test-user.keys | cut -d: -f2 | sed 's/ //g')
USER_KEY_SEARCH=$(cleos wallet keys | grep "$EOSUserPublicKey" | wc -l)
if [ $USER_KEY_SEARCH -lt 1 ]; then
  cleos wallet import --name ep-test-wallet --private-key $EOSUserPrivateKey
fi

# boot strap
bash "${ROOT_DIR}"/bin/reactivate_contract.sh

cleos create account eosio eosio.eptest $EOSUserPublicKey
cleos set contract eosio.eptest ./unittests/test-contracts/payloadless
sleep 2

###
stop_nodeos
###
sleep 2
###
start_nodeos "READONLY"
###
