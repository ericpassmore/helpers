#!/bin/env bash

BRANCH=${1:-release/5.0}

# must not be root to run
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
cd "${LEAP_GIT_DIR:?}" || exit

if [ -f ~/env ]; then
  source ~/env
else
  echo "Cannot find ~/env"
  exit
fi

git fetch origin $BRANCH
git checkout $BRANCH
git pull origin $BRANCH
git submodule update --init --recursive

rm -rf $LEAP_BUILD_DIR
mkdir "$LEAP_BUILD_DIR"
mkdir "$LEAP_BUILD_DIR"/signed-outputs

cd "${LEAP_BUILD_DIR:?}" || exit
docker build -f "$LEAP_GIT_DIR"/tools/reproducible.Dockerfile -o ./signed-outputs/ "$LEAP_GIT_DIR"

sleep 2
cd signed-outputs || exit
CHECKSUM=$(sha256sum ./leap_[0-9]*_amd64.deb)
echo "Checksum: ${CHECKSUM} "

gpg --detach-sign --armor --default-key "${GIT_KEY}" leap_[0-9]*_amd64.deb
