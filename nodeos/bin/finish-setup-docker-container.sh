#!/usr/bin/env bash

CDT_GIT_COMMIT_TAG=${1:-v4.0.1}

echo "LINKING HELPER BIN DIR"
ln -s /local/eosnetworkfoundation/repos/helpers/nodeos/bin /local/eosnetworkfoundation/bin
source /local/eosnetworkfoundation/bin/nodeos_config.sh

cd "${ROOT_DIR:?}"/deb || exit
echo "GET LEAP DEB"
wget https://github.com/AntelopeIO/leap/releases/download/v5.0.2/leap_5.0.2_amd64.deb

echo "START BUILDING CDT"
cd "${ROOT_DIR:?}"/repos/cdt || exit

git checkout $CDT_GIT_COMMIT_TAG
git pull origin $CDT_GIT_COMMIT_TAG

mkdir build
cd build || exit
cmake .. >> "$LOG_DIR"/cdt_build_log.log 2>&1
make -j 8 >> "$LOG_DIR"/cdt_build_log.log 2>&1
echo "FINSIHED BUILDING CDT"

mkdir $WALLET_DIR $CONFIG_DIR $DATA_DIR

## su to root and install
# cd /local/eosnetworkfoundation/deb/
# dpkg -i ./leap_[5-6].[0-9].[0-9]*_amd64.deb
# cd /local/eosnetworkfoundation/repos/cdt/build || exit
# make install
