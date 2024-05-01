#!/bin/env bash

set -x

cd /local/eosnetworkfoundation/downloads/spring || exit
git checkout main
git pull origin main
/usr/bin/python3 \
  /local/eosnetworkfoundation/repos/ericpassmore/helpers/git/draft-release-notes.py \
  lastweek --html --no-html-footer > /local/www/html/spring/release_notes/release-notes-this-week.html
git checkout hotstuff_integration
git pull origin hotstuff_integration
/usr/bin/python3 \
    /local/eosnetworkfoundation/repos/ericpassmore/helpers/git/draft-release-notes.py \
    lastweek --html --no-html-header >> /local/www/html/spring/release_notes/release-notes-this-week.html
