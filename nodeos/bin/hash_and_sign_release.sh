#!/bin/env bash

BRANCH=${1:-release/5.0}
# set to "tty" for sign on command line
PARENT_SHELL=${2:-cron}
TITLE=${3}

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
CHECKSUM=$(sha256sum "$LEAP_BUILD_DIR"/signed-outputs/local/leap_[0-9]*_amd64.deb)
echo "${CHECKSUM}" > "$LEAP_BUILD_DIR"/signed-outputs/local-sha256sum.txt

## get ci deb
python3 /local/eosnetworkfoundation/repos/ericpassmore/helpers/github/download_artifacts.py \
  --branch $BRANCH \
  --download-dir "$LEAP_BUILD_DIR"/signed-outputs/ci \
  --bearer-token $BEARER > "$LEAP_BUILD_DIR"/signed-outputs/ci-package-info.json

## parse json
LOCAL_CHECKSUM=$(cat "$LEAP_BUILD_DIR"/signed-outputs/local-sha256sum.txt | cut -d" " -f1)
CI_CHECKSUM=$(cat "$LEAP_BUILD_DIR"/signed-outputs/ci-package-info.json | \
   python3 -c "import sys
import json
print (json.load(sys.stdin)['sha256sum'])")

if [ "$LOCAL_CHECKSUM" == "$CI_CHECKSUM" ]; then
  echo "checksums are equal you may sign"
  if [ $PARENT_SHELL == "tty" ]; then
     cd "${LEAP_BUILD_DIR:?}"/signed-outputs || exit
     gpg --detach-sign --armor --default-key "${GIT_KEY}" "$LEAP_BUILD_DIR"/signed-outputs/local/leap_[0-9]*_amd64.deb
     GIT_LONG_SHA=$(cat "$LEAP_BUILD_DIR"/signed-outputs/ci-package-info.json | \
       python3 -c "import sys
import json
print (json.load(sys.stdin)['gitcommitsha'])")
     cd "${LEAP_GIT_DIR:?}" || exit
     GIT_SHORT_SHA=$(git rev-parse --short $GIT_LONG_SHA)
     PR_NUM=$(cat "$LEAP_BUILD_DIR"/signed-outputs/ci-package-info.json | \
       python3 -c "import sys
import json
print (json.load(sys.stdin)['pr_num'])")
     PR_TITLE=$(cat "$LEAP_BUILD_DIR"/signed-outputs/ci-package-info.json | \
  python3 -c "import sys
import json
print (json.load(sys.stdin)['pr_title'])")
     MERGE_TIME=$(cat "$LEAP_BUILD_DIR"/signed-outputs/ci-package-info.json | \
python3 -c "import sys
import json
print (json.load(sys.stdin)['merge_time'])")

     cp "${LEAP_BUILD_DIR}"/signed-outputs/local/leap_*.deb.asc "${HTML_ROOT}"/leap/signatures/${GIT_SHORT_SHA}.asc
     DEB_FILE=$(basename "${LEAP_BUILD_DIR}"/signed-outputs/local/leap_*.deb)
     DEB_FILE_SHA="${DEB_FILE%.*}_${GIT_SHORT_SHA}.deb"
     DOWNLOAD_URL=/leap/packages/"${DEB_FILE_SHA}"
     cp "${LEAP_BUILD_DIR}"/signed-outputs/local/"${DEB_FILE}" "${HTML_ROOT}"/leap/packages/"${DEB_FILE_SHA}"

     if [ -z "${TITLE}" ]; then
         TITLE=$PR_TITLE
     fi

     python3 /local/eosnetworkfoundation/repos/ericpassmore/leap-website/create_build_history_json.py \
     --file "${HTML_ROOT}"/leap/leap-verified-builds.json \
     --merge-time "${MERGE_TIME}" \
     --branch "${BRANCH}" \
     --git-short-sha "${GIT_SHORT_SHA}" \
     --full-checksum "$LOCAL_CHECKSUM" \
     --pr-number "${PR_NUM}" \
     --title "${TITLE}" \
     --download-url "${DOWNLOAD_URL}" \
     --deb-file-name "${DEB_FILE_SHA}"
  fi
else
  echo "WARNING: checksums mismatch Local: $LOCAL_CHECKSUM CI: $CI_CHECKSUM"
fi
