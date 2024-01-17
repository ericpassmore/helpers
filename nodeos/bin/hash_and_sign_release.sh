#!/bin/env bash

BRANCH=${1:-release/5.0}

TUID=$(id -ur)
# must not be root to run
if [ "$TUID" -eq 0 ]; then
  echo "Trying to run as root user exiting"
  exit
fi

## Source Variables for Run
NODEOS_CONFIG=/local/eosnetworkfoundation/bin/nodeos_config.sh
if [ -f "$NODEOS_CONFIG" ]; then
  source "$NODEOS_CONFIG"
else
  echo "Cannot find nodeos config ${NODEOS_CONFIG}"
  exit
fi
ENV=~/env
if [ -f "$ENV" ]; then
  source "$ENV"
else
  echo "Cannot find ENV file ${ENV}"
  exit
fi

## check git sha of last run
if [ -f "$LEAP_BUILD_DIR"/signed-outputs/ci-package-info.json ]; then
  CI_LAST_GIT_SHA=$(cat "$LEAP_BUILD_DIR"/signed-outputs/ci-package-info.json | \
    python3 -c "import sys
import json
print (json.load(sys.stdin)['gitcommitsha'])")
fi

## update git
cd "${LEAP_GIT_DIR:?}" || exit
git fetch origin $BRANCH
git checkout $BRANCH
git pull origin $BRANCH
# has anything changed since last run?
CURRENT_GIT_SHA=$(git rev-parse HEAD | tr -d '\n')
if [ $CURRENT_GIT_SHA == ${CI_LAST_GIT_SHA:-0} ]; then
  echo "No new commits, exiting now"
  exit
fi

git submodule update --init --recursive

## setup build dir
rm -rf $LEAP_BUILD_DIR
mkdir "$LEAP_BUILD_DIR"
mkdir "$LEAP_BUILD_DIR"/signed-outputs
mkdir "$LEAP_BUILD_DIR"/signed-outputs/ci
mkdir "$LEAP_BUILD_DIR"/signed-outputs/local

## run local build
cd "${LEAP_BUILD_DIR:?}" || exit
docker build -f "$LEAP_GIT_DIR"/tools/reproducible.Dockerfile -o ./signed-outputs/local "$LEAP_GIT_DIR"

sleep 2
cd signed-outputs/local || exit
CHECKSUM=$(sha256sum ./leap_[0-9]*_amd64.deb)
echo "${CHECKSUM}" > "$LEAP_BUILD_DIR"/signed-outputs/local-sha256sum.txt

## get ci deb
python3 /local/eosnetworkfoundation/repos/ericpassmore/helpers/github/download_artifacts.py \
  --branch $BRANCH \
  --download-dir "$LEAP_BUILD_DIR"/signed-outputs/ci \
  --bearer-token $BEARER > "$LEAP_BUILD_DIR"/signed-outputs/ci-package-info.json

LOCAL_CHECKSUM=$(cat "$LEAP_BUILD_DIR"/signed-outputs/local-sha256sum.txt | cut -d" " -f2)
CI_CHECKSUM=$(cat "$LEAP_BUILD_DIR"/signed-outputs/ci-package-info.json | \
   python3 -c "import sys
import json
print (json.load(sys.stdin)['sha256sum'])")

if [ "$LOCAL_CHECKSUM" == "$CI_CHECKSUM" ]; then
  echo "checksums are equal you may sign"
else
  echo "WARNING: checksums mismatch Local: $LOCAL_CHECKSUM CI: $CI_CHECKSUM"
fi

#gpg --detach-sign --armor --default-key "${GIT_KEY}" leap_[0-9]*_amd64.deb
