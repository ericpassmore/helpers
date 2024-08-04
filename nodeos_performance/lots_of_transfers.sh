#!/usr/bin/env bash

WALLET_DIR=${HOME}/eosio-wallet
BUILD_TEST_DIR=/local/eosnetworkfoundation/spring_build/tests
TRX_LOG_DIR=/bigata1/log/trx_generator

HTTP_URL=https://api.spring-beta2.jungletestnet.io:443
P2P_HOST=p2p.spring-beta2.jungletestnet.io
PEER2PEERPORT=9898
GENERATORID=0
ACCOUNTS=("purplepurple" "orangeorange" "pinkpink1111" "blueblue1111" "yellowyellow" "greengreen11")
PRIVKEYS=()

unset COMMA_SEP_ACCOUNTS
unset COMMA_SEP_KEYS

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
EOS_ROOT_PRIVATE_KEY=$(grep Private "${WALLET_DIR}"/finality-test-network.keys | head -1 | cut -d: -f2 | sed 's/ //g')
cleos wallet import --name load-test --private-key $EOS_ROOT_PRIVATE_KEY


for name in "${ACCOUNTS[@]}"; do
  [ ! -s "$WALLET_DIR/${name}.keys" ] && cleos create key --to-console > "$WALLET_DIR/${name}.keys"
  PRIVKEYS+=($(grep Private "$WALLET_DIR/${name}.keys" | head -1 | cut -d: -f2 | sed 's/ //g'))
  cleos wallet import --name load-test --private-key ${PRIVKEYS[-1]}
  cleos --url $HTTP_URL get account ${name} > /dev/null 2>&1
  if [ $? != 0 ]; then
    PUB_KEY=$(grep Public "$WALLET_DIR/${name}.keys" | head -1 | cut -d: -f2 | sed 's/ //g')
    echo "Create Account ${name}"
    cleos --url $HTTP_URL system newaccount eosio ${name:?} ${PUB_KEY:?} --stake-net "500 EOS" --stake-cpu "500 EOS" --buy-ram "1000 EOS"
    sleep 3
    cleos --url $HTTP_URL transfer eosio ${name} "10000 EOS" "transfer test"
    cleos --url $HTTP_URL system delegatebw $name $name "10.0 EOS" "10.0 EOS"
    cleos --url $HTTP_URL system buyram $name $name "10.0 EOS" -p $name
  fi
  COMMA_SEP_ACCOUNTS+="${name},"
done
COMMA_SEP_ACCOUNTS=${COMMA_SEP_ACCOUNTS%,}


for key in "${PRIVKEYS[@]}"; do
  COMMA_SEP_KEYS+="${key},"
done
COMMA_SEP_KEYS=${COMMA_SEP_KEYS%,}

[ ! -d $TRX_LOG_DIR ] && mkdir $TRX_LOG_DIR

CHAIN_ID=$(cleos --url $HTTP_URL get info | grep chain_id | cut -d:  -f2 | sed 's/[ ",]//g')
LIB_ID=$(cleos --url $HTTP_URL get info | grep last_irreversible_block_id | cut -d:  -f2 | sed 's/[ ",]//g')
sleep 3
${BUILD_TEST_DIR}/trx_generator/trx_generator --generator-id $GENERATORID \
     --chain-id $CHAIN_ID \
     --target-tps 1000 \
     --contract-owner-account eosio \
     --accounts $COMMA_SEP_ACCOUNTS \
     --priv-keys $COMMA_SEP_KEYS \
     --last-irreversible-block-id $LIB_ID \
     --log-dir $TRX_LOG_DIR \
     --peer-endpoint-type p2p \
     --peer-endpoint $P2P_HOST \
     --port $PEER2PEERPORT
