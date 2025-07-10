#!/bin/env bash

BRANCH=${1:-release/5.0}
# set to "tty" for sign on command line
PARENT_SHELL=${2:-cron}
TITLE=${3}
LAST_RELEASE_CHECKPOINT=${4:-HEAD}
CHECK_NEW_COMMIT=0

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
if [ -f "$SPRING_BUILD_DIR"/signed-outputs/ci-package-info.json ]; then
  CI_LAST_GIT_SHA=$(cat "$SPRING_BUILD_DIR"/signed-outputs/ci-package-info.json | \
    python3 -c "import sys
import json
print (json.load(sys.stdin)['gitcommitsha'])")
fi

## update git
cd "${SPRING_GIT_DIR:?}" || exit
git fetch origin $BRANCH
git checkout $BRANCH
git pull origin $BRANCH
# has anything changed since last run?
CURRENT_GIT_SHA=$(git rev-parse HEAD | tr -d '\n')
if [ $CURRENT_GIT_SHA == ${CI_LAST_GIT_SHA:-0} ] && [ $CHECK_NEW_COMMIT == 1 ]; then
  echo "No new commits, exiting now"
  exit
fi

git submodule update --init --recursive

## setup build dir
rm -rf ${SPRING_BUILD_DIR}/signed-outputs/
mkdir "$SPRING_BUILD_DIR"/signed-outputs
mkdir "$SPRING_BUILD_DIR"/signed-outputs/ci
mkdir "$SPRING_BUILD_DIR"/signed-outputs/local

## run local build
docker build --build-arg BUILDKIT_CONTEXT_KEEP_GIT_DIR=1 -f tools/reproducible.Dockerfile -o ${SPRING_BUILD_DIR}/signed-outputs/ https://github.com/AntelopeIO/spring.git#${BRANCH}

sleep 2
CHECKSUM=$(sha256sum "$SPRING_BUILD_DIR"/signed-outputs/local/antelope-spring_[0-9]*_amd64.deb)
echo "${CHECKSUM}" > "$SPRING_BUILD_DIR"/signed-outputs/local-sha256sum.txt

## get ci deb
python3 /local/eosnetworkfoundation/repos/ericpassmore/helpers/github/download_artifacts.py \
  --branch $BRANCH \
  --download-dir "$SPRING_BUILD_DIR"/signed-outputs/ci \
  --bearer-token $BEARER > "$SPRING_BUILD_DIR"/signed-outputs/ci-package-info.json

## parse json
LOCAL_CHECKSUM=$(cat "$SPRING_BUILD_DIR"/signed-outputs/local-sha256sum.txt | cut -d" " -f1)
CI_CHECKSUM=$(cat "$SPRING_BUILD_DIR"/signed-outputs/ci-package-info.json | \
   python3 -c "import sys
import json
print (json.load(sys.stdin)['sha256sum'])")

if [ "$LOCAL_CHECKSUM" == "$CI_CHECKSUM" ]; then
  echo "checksums are equal you may sign"
  if [ $PARENT_SHELL == "tty" ]; then
     cd "${SPRING_BUILD_DIR:?}"/signed-outputs || exit
     gpg --detach-sign --armor --default-key "${GIT_KEY}" "$SPRING_BUILD_DIR"/signed-outputs/local/antelope-spring_[0-9]*_amd64.deb
     GIT_LONG_SHA=$(cat "$SPRING_BUILD_DIR"/signed-outputs/ci-package-info.json | \
       python3 -c "import sys
import json
print (json.load(sys.stdin)['gitcommitsha'])")
     cd "${SPRING_GIT_DIR:?}" || exit
     GIT_SHORT_SHA=$(git rev-parse --short $GIT_LONG_SHA)
     PR_NUM=$(cat "$SPRING_BUILD_DIR"/signed-outputs/ci-package-info.json | \
       python3 -c "import sys
import json
print (json.load(sys.stdin)['pr_num'])")
     PR_TITLE=$(cat "$SPRING_BUILD_DIR"/signed-outputs/ci-package-info.json | \
  python3 -c "import sys
import json
print (json.load(sys.stdin)['pr_title'])")
     MERGE_TIME=$(cat "$SPRING_BUILD_DIR"/signed-outputs/ci-package-info.json | \
python3 -c "import sys
import json
print (json.load(sys.stdin)['merge_time'])")

     cp "${SPRING_BUILD_DIR}"/signed-outputs/local/antelope-spring_*.deb.asc "${HTML_ROOT}"/spring/signatures/${GIT_SHORT_SHA}.asc
     DEB_FILE=$(basename "${SPRING_BUILD_DIR}"/signed-outputs/local/antelope-spring_*.deb)
     DEB_FILE_SHA="${DEB_FILE%.*}_${GIT_SHORT_SHA}.deb"
     DOWNLOAD_URL=/spring/packages/"${DEB_FILE_SHA}"
     cp "${SPRING_BUILD_DIR}"/signed-outputs/local/"${DEB_FILE}" "${HTML_ROOT}"/spring/packages/"${DEB_FILE_SHA}"

     if [ -z "${TITLE}" ]; then
         TITLE=$PR_TITLE
     fi

     ## create mini-release notes
     # notes from LAST_RELEASE_CHECKPOINT TO HEAD
     RELEASE_NOTES=""
     if [ "$LAST_RELEASE_CHECKPOINT" != "HEAD" ]; then
       cd "${SPRING_GIT_DIR:?}" || exit

       python3 /local/eosnetworkfoundation/repos/ericpassmore/leap-website/create_build_history_json.py \
          --file "${HTML_ROOT}"/spring/spring-verified-builds.json \
          --merge-time "${MERGE_TIME}" \
          --branch "${BRANCH}" \
          --git-short-sha "${GIT_SHORT_SHA}" \
          --full-checksum "$LOCAL_CHECKSUM" \
          --pr-number "${PR_NUM}" \
          --title "${TITLE}" \
          --release-notes "YES" \
          --download-url "${DOWNLOAD_URL}" \
          --deb-file-name "${DEB_FILE_SHA}"

       cd "${SPRING_BUILD_DIR:?}" || exit
     else
       # no release notes otherwise same call as above
       python3 /local/eosnetworkfoundation/repos/ericpassmore/leap-website/create_build_history_json.py \
         --file "${HTML_ROOT}"/spring/spring-verified-builds.json \
         --merge-time "${MERGE_TIME}" \
         --branch "${BRANCH}" \
         --git-short-sha "${GIT_SHORT_SHA}" \
         --full-checksum "$LOCAL_CHECKSUM" \
         --pr-number "${PR_NUM}" \
         --title "${TITLE}" \
         --download-url "${DOWNLOAD_URL}" \
         --deb-file-name "${DEB_FILE_SHA}"
     fi

  fi
else
  echo "WARNING: checksums mismatch Local: $LOCAL_CHECKSUM CI: $CI_CHECKSUM"
fi
