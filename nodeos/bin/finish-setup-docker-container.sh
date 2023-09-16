#!/usr/bin/env bash

cd /local/eosnetworkfoundation/ || exit
cp -r /local/eosnetworkfoundation/repos/ericpassmore/helpers/nodeos/bin .
cp -r /local/eosnetworkfoundation/repos/ericpassmore/helpers/nodeos/config .
cp -r /local/eosnetworkfoundation/repos/ericpassmore/helpers/nodeos/docker .
cp -r /local/eosnetworkfoundation/repos/ericpassmore/helpers/nodeos/transactions .
cd /local/eosnetworkfoundation/deb  || exit
wget https://github.com/AntelopeIO/leap/releases/download/v4.0.4/leap_4.0.4-ubuntu22.04_amd64.deb
wget https://github.com/AntelopeIO/cdt/releases/download/v4.0.0/cdt_4.0.0_amd64.deb
