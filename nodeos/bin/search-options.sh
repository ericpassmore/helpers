#!/bin/env bash

SEARCH_DIR=${1:-~/eosnetworkfoundation/repos/antelope/spring}
grep -r "options.at" ${SEARCH_DIR}/plugins | sed -E 's/.+options\.at\([[:space:]]*"(.+)"[[:space:]]*\).+/\1/'
