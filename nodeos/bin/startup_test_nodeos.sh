#!/usr/bin/env bash

COMMAND=$1


#########
# Function to start nodeos
#########
start_nodeos() {
  TYPE=${1:-PRODUCER}
  FROM_GENESIS=${2:-NO}

  # setup proper configuration
  if [ "$TYPE" == "READONLY" ]; then
    cp -f ${CONFIG_DIR}/test-readonly-config.ini ${CONFIG_DIR}/config.ini
  else
    cp -f ${CONFIG_DIR}/test-producer-config.ini ${CONFIG_DIR}/config.ini
  fi

  # startup
  if [ "$FROM_GENESIS" == "YES" ]; then
    nodeos --genesis-json "$CONFIG_DIR"/genesis.json --data-dir "$DATA_DIR" --config "$CONFIG_DIR"/config.ini >> "$LOG_DIR"/nodeos.log 2>&1 &
    PID=$!
    echo "Started $1 Nodeos From Genesis with $DATA_DIR and ${CONFIG_DIR}/config.ini"
  else
    nodeos --data-dir "$DATA_DIR" --config "$CONFIG_DIR"/config.ini >> "$LOG_DIR"/nodeos.log 2>&1 &
    PID=$!
    echo "Started $1 Nodeos with $DATA_DIR and ${CONFIG_DIR}/config.ini"
  fi

  sleep 1

  # Check for running nodeos; if not running cat out log
  if [ -z "$PID" ]; then
    if [ -f "$LOG_DIR"/nodeos.log ]; then
      tail -20 "$LOG_DIR"/nodeos.log
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

########
# Function Create Config
#######
build_config() {
  EOSRootPrivateKey=$(grep Private "${WALLET_DIR}"/root-user.keys | cut -d: -f2 | sed 's/ //g')
  EOSRootPublicKey=$(grep Public "${WALLET_DIR}"/root-user.keys | cut -d: -f2 | sed 's/ //g')

  sed "s/EOSRootPublicKey/$EOSRootPublicKey/" "$ROOT_DIR"/repos/helpers/nodeos/config/test-producer-config.ini \
     | sed "s/EOSRootPrivateKey/$EOSRootPrivateKey/" > "${CONFIG_DIR}"/test-producer-config.ini
  sed "s/EOSRootPublicKey/$EOSRootPublicKey/" "$ROOT_DIR"/repos/helpers/nodeos/config/test-readonly-config.ini \
     | sed "s/EOSRootPrivateKey/$EOSRootPrivateKey/" > "${CONFIG_DIR}"/test-readonly-config.ini

  NOW=$(date +%FT%T.%3N)
  GENESIS_FILE="$ROOT_DIR"/repos/helpers/nodeos/config/genesis.json
  sed "s/\"initial_key\": \".*\",/\"initial_key\": \"${EOSRootPublicKey}\",/" $GENESIS_FILE > /tmp/genesis.json
  sed "s/\"initial_timestamp\": \".*\",/\"initial_timestamp\": \"${NOW}\",/" /tmp/genesis.json > ${CONFIG_DIR}/genesis.json
}

##########
# open wallet add keys if needed
#######
open_wallet() {
  EOSRootPrivateKey=$(grep Private "${WALLET_DIR}"/root-user.keys | cut -d: -f2 | sed 's/ //g')
  EOSRootPublicKey=$(grep Public "${WALLET_DIR}"/root-user.keys | cut -d: -f2 | sed 's/ //g')

  # Add Private Keys if needed
  if [ ! -f "${WALLET_DIR}"/all-wallet.wallet ]; then
    cleos wallet create --name all-wallet --file "${WALLET_DIR}"/all-wallet.pw
  fi
  IS_WALLET_OPEN=$(cleos wallet list | grep all-wallet | grep -F '*' | wc -l)
  # not open then it is locked so unlock it
  if [ $IS_WALLET_OPEN -lt 1 ]; then
    cat "${WALLET_DIR}"/all-wallet.pw | cleos wallet unlock --name all-wallet --password
  fi
  # Import Root Private Key
  ROOT_KEY_SEARCH=$(cleos wallet keys | grep "$EOSRootPublicKey" | wc -l)
  if [ $ROOT_KEY_SEARCH -lt 1 ]; then
    cleos wallet import --name all-wallet --private-key $EOSRootPrivateKey
  fi
}

##########
# Start from Genesis
#######
start_nodeos_from_genesis() {
  ## Check not existing dir
  if [ -f "${DATA_DIR}"/state/shared_memory.bin ]; then
    echo "ERROR MUST REMOVE ${DATA_DIR}/state/shared_memory.bin BEFORE STARTING FROM GENESIS"
    exit 1
  fi

  build_config

  # empty log
  :> ${LOG_DIR}/nodeos.log
  start_nodeos PRODUCER YES

  # boot strap
  open_wallet
  EOSRootPublicKey=$(grep Public "${WALLET_DIR}"/root-user.keys | cut -d: -f2 | sed 's/ //g')
  # Three args
  # endpoint
  # contract dir
  # root public key for account creation
  bash "${ROOT_DIR}"/bin/first_boot_actions.sh "http://127.0.0.1:8888" \
    "${ROOT_DIR}"/repos/eos-system-contracts/build/contracts \
    $EOSRootPublicKey
}

#######
# clean out data files
######
clean_nodeos() {
  [ -f "$DATA_DIR"/blocks/blocks.log ] && rm -f "$DATA_DIR"/blocks/blocks.log
  [ -f "$DATA_DIR"/blocks/blocks.index ] && rm -f "$DATA_DIR"/blocks/blocks.index
  [ -f "$DATA_DIR"/state/shared_memory.bin ] && rm -f "$DATA_DIR"/state/shared_memory.bin
  [ -f "$DATA_DIR"/state/code_cache.bin ] && rm -f "$DATA_DIR"/state/code_cache.bin
  [ -f "$DATA_DIR"/blocks/reversible/fork_db.dat ] && rm -f "$DATA_DIR"/blocks/reversible/fork_db.dat
}

## Source Config, provides the following:
# ROOT_DIR
# SPRING_GIT_DIR
# SPRING_BUILD_DIR
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

set -x
[ ! -f "$WALLET_DIR"/root-user.keys ] && cleos create key --to-console > "$WALLET_DIR"/root-user.keys

case $COMMAND in
  START)
    echo "Starting the system..."
    start_nodeos PRODUCER NO
    # Insert commands to start the system here
    ;;
  STOP)
    echo "Stopping the system..."
    stop_nodeos
    # Insert commands to stop the system here
    ;;
  GENESIS)
    echo "Initializing from genesis..."
    start_nodeos_from_genesis
    # Insert commands for genesis process here
    ;;
  CLEAN)
    echo "Cleaning up resources..."
    clean_nodeos
    # Insert cleanup commands here
    ;;
  *)
    echo "Invalid command: $COMMAND"
    echo "Valid commands are: START, STOP, GENESIS, CLEAN."
    ;;
esac
