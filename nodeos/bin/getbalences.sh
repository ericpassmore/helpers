#!/bin/bash

echo $1
cleos -u https://jungle4.cryptolions.io:443 get table eosio.token $1 accounts | jq '.rows[]'
cleos -u https://jungle4.cryptolions.io:443 get table core.vaulta $1 accounts | jq '.rows[]'

