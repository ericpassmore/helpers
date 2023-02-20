#!/usr/bin/env bash

ROOT_DIR="/local/eosnetworkfoundation/bin/"
USER=eric
su -c "$ROOT_DIR/shutdown.sh" $USER
su -c "$ROOT_DIR/nightly_build.sh" $USER
su -c "$ROOT_DIR/nightly_test.sh" $USER
"$ROOT_DIR/nodeos_install.sh"
su -c "$ROOT_DIR/startup.sh" $USER
