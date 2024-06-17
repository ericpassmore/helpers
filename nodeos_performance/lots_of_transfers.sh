#!/usr/bin/env bash

WALLET_DIR=${HOME}/eosio-wallet
BUILD_TEST_DIR=/local/eosnetworkfoundation/spring_build/tests
LOG_DIR=/bigata1/log/trx_generator

PEER2PEERPORT=1444
CHAINID=3a2c859826a43827acb6be8ede451b8432a1b056aad7992a72840fe61d58cb25
GENERATORID=0
ACCOUNTS=("purple" "orange" "pink" "blue" "yellow" "green")
PRIVKEYS=()

# setup wallets, open wallet, add keys if needed
[ ! -d "$WALLET_DIR" ] && mkdir -p "$WALLET_DIR"
if [ ! -f "${WALLET_DIR}"/load-test.wallet ]; then
  cleos wallet create --name load-test --file "${WALLET_DIR}"/load-test.pw
fi
IS_WALLET_OPEN=$(cleos wallet list | grep load-test | grep -F '*' | wc -l)
# not open then it is locked so unlock it
if [ $IS_WALLET_OPEN -lt 1 ]; then
  cat "${WALLET_DIR}"/load-test.pw | cleos wallet unlock --name load-test --password
fi
cleos wallet import --name load-test --private-key 5KcFnv366GTKabNXyDvGCyA5VBzMuzXCZdGXApsvpN17KuHYWAh


for name in "${ACCOUNTS[@]}"; do
  # create keys if they don't already exist
  [ ! -s "$WALLET_DIR/${name}.keys" ] && cleos create key --to-console > "$WALLET_DIR/${name}.keys"
  PRIVKEYS+=($(grep Private "$WALLET_DIR/${name}.keys" | head -1 | cut -d: -f2 | sed 's/ //g'))
  cleos wallet import --name load-test --private-key ${PRIVKEYS[-1]}
  # create account if needed
  cleos get account ${name} > /dev/null 2>&1
  if [ $? != 0 ]; then
    PUB_KEY=$(grep Public "$WALLET_DIR/${name}.keys" | head -1 | cut -d: -f2 | sed 's/ //g')
    echo "Create Account ${name}"
    cleos system newaccount eosio ${name:?} ${PUB_KEY:?} --stake-net "500 EOS" --stake-cpu "500 EOS" --buy-ram "1000 EOS"
    sleep 3
    cleos transfer eosio ${name} "10000 EOS" "transfer test"
  fi
  COMMA_SEP_ACCOUNTS+="${name},"
done
COMMA_SEP_ACCOUNTS=${COMMA_SEP_ACCOUNTS%,}

for key in "${PRIVKEYS[@]}"; do
  COMMA_SEP_KEYS+="${key},"
done
COMMA_SEP_KEYS=${COMMA_SEP_KEYS%,}

[ ! -d $LOG_DIR ] && mkdir $LOG_DIR

LIB_ID=$(cleos get info | grep last_irreversible_block_id | cut -d:  -f2 | sed 's/[ ",]//g')

${BUILD_TEST_DIR}/trx_generator/trx_generator --generator-id $GENERATORID \
     --chain-id $CHAINID \
     --contract-owner-account eosio \
     --accounts $COMMA_SEP_ACCOUNTS \
     --priv-keys $COMMA_SEP_KEYS \
     --last-irreversible-block-id $LIB_ID \
     --log-dir $LOG_DIR \
     --peer-endpoint-type p2p \
     --port $PEER2PEERPORT
