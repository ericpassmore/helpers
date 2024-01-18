#!/bin/env bash

BRANCH=${1:-release/5.0}
# set to "tty" for sign on command line
PARENT_SHELL=${2:-cron}

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
    DOWNLOAD_URL=$(cat "$LEAP_BUILD_DIR"/signed-outputs/ci-package-info.json | \
python3 -c "import sys
import json
print (json.load(sys.stdin)['download_url'])")
     echo "<td>${MERGE_TIME}</td> " >> "${HTML_ROOT}"/leap/leap-build-history.txt
     echo "<td>${BRANCH}</td> " >> "${HTML_ROOT}"/leap/leap-build-history.txt
     echo "<td>${GIT_SHORT_SHA}</td> " >> "${HTML_ROOT}"/leap/leap-build-history.txt
     echo "<td>${PR_NUM}</td> " >> "${HTML_ROOT}"/leap/leap-build-history.txt
     echo "<td>${PR_TITLE}</td>" >> "${HTML_ROOT}"/leap/leap-build-history.txt
     echo "<td><a href='${DOWNLOAD_URL}'>Download Deb</a></td>" >> "${HTML_ROOT}"/leap/leap-build-history.txt
     cp "${LEAP_BUILD_DIR}/signed-outputs/local/leap_*.deb.asc" "${HTML_ROOT}"/leap/signatures/${GIT_SHORT_SHA}.asc
     echo '<!DOCTYPE html><html><body>' > "${HTML_ROOT}"/leap/verified-builds.html
     echo '<table><thead><tr><th>Merge Time</th><th>Branch</th><th>Git Commit</th><th>PR Num</th>' >> "${HTML_ROOT}"/leap/verified-builds.html
     echo '<th>PR Title</th><th>Signature</th></tr></thead>' >> "${HTML_ROOT}"/leap/verified-builds.html
     echo '<tbody>' >> "${HTML_ROOT}"/leap/verified-builds.html
     while read -r line
     do
       sha=$(echo $line | cut -d" " -f3 | sed 's/^<td>\([0-9a-z]\+\)<\/td>$/\1/')
       SIGNED_LINK="<a href=/leap/signatures/${sha}.asc>Signature</a>"
       echo "<tr>" >> "${HTML_ROOT}"/leap/verified-builds.html
       echo "${line}" "<td>${SIGNED_LINK}<td>" >> "${HTML_ROOT}"/leap/verified-builds.html
       echo "</tr>" >> "${HTML_ROOT}"/leap/verified-builds.html
     done < "${HTML_ROOT}"/leap/leap-build-history.txt
     echo "</tbody></table></body></html>" >> "${HTML_ROOT}"/leap/verified-builds.html
  fi
else
  echo "WARNING: checksums mismatch Local: $LOCAL_CHECKSUM CI: $CI_CHECKSUM"
fi
