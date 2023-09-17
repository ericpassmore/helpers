#!/usr/bin/env bash

cd /local/eosnetworkfoundation/ || exit
mkdir downloads
cd /local/eosnetworkfoundation/downloads || exit
ln -s ../repos/leap leap
cd /local/eosnetworkfoundation/ || exit
cp -r /local/eosnetworkfoundation/repos/helpers/nodeos/bin .
cp -r /local/eosnetworkfoundation/repos/helpers/nodeos/config .
cp -r /local/eosnetworkfoundation/repos/helpers/nodeos/docker .
cp -r /local/eosnetworkfoundation/repos/helpers/nodeos/transactions .
cd /local/eosnetworkfoundation/deb  || exit
wget https://github.com/AntelopeIO/leap/releases/download/v4.0.4/leap_4.0.4-ubuntu22.04_amd64.deb
wget https://github.com/AntelopeIO/cdt/releases/download/v4.0.0/cdt_4.0.0_amd64.deb
cd /local/eosnetworkfoundation/ || exit

source ./bin/nodeos_config.sh
mkdir $WALLET_DIR $CONFIG_DIR $DATA_DIR
if [ ! -f $WALLET_DIR/ep-test-user.keys ]; then
  cleos create key --file $WALLET_DIR/ep-test-user.keys
fi
if [ ! -f $WALLET_DIR/ep-test-root.keys ]; then
  cleos create key --file $WALLET_DIR/ep-test-root.keys
fi
EOSRootPrivateKey=$(grep Private "${WALLET_DIR}"/ep-test-root.keys | cut -d: -f2 | sed 's/ //g')
EOSRootPublicKey=$(grep Public "${WALLET_DIR}"/ep-test-root.keys | cut -d: -f2 | sed 's/ //g')
EOSUserPublicKey=$(grep Public "${WALLET_DIR}"/ep-test-user.keys | cut -d: -f2 | sed 's/ //g')
EOSUserPrivateKey=$(grep Private "${WALLET_DIR}"/ep-test-user.keys | cut -d: -f2 | sed 's/ //g')
ROOT_KEY_SEARCH=$(cleos wallet keys | grep "$EOSRootPublicKey" | wc -l)
if [ $ROOT_KEY_SEARCH -lt 1 ]; then
  cleos wallet import --name ep-test-wallet --private-key $EOSRootPrivateKey
fi
USER_KEY_SEARCH=$(cleos wallet keys | grep "$EOSUserPublicKey" | wc -l)
if [ $USER_KEY_SEARCH -lt 1 ]; then
  cleos wallet import --name ep-test-wallet --private-key $EOSUserPrivateKey
fi
sed "s/EOSRootPublicKey/$EOSRootPublicKey/" "${ROOT_DIR}"/config/test-producer-config.ini \
   | sed "s/EOSRootPrivateKey/$EOSRootPrivateKey/" > "${CONFIG_DIR}"/config.ini
# nodeos --data-dir "$DATA_DIR" --config-dir "$CONFIG_DIR" >> "$LOG_DIR"/nodeos.log 2>&1 &
