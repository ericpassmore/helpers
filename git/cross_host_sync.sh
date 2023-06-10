#!/usr/bin/env bash

C_ROOT_DIR="/Users/eric/eosnetworkfoundation/repos"
S_ROOT_DIR="/Users/eric/superbee/local/eosnetworkfoundation/repos"
WORKING_DIR=$(pwd)
ORG_DIR=$(echo ${WORKING_DIR} | cut -d"/" -f6)
REPO=$(echo ${WORKING_DIR} | cut -d"/" -f7)

rsync -av "$C_ROOT_DIR/$ORG_DIR/$REPO" "$S_ROOT_DIR/$ORG_DIR/"
