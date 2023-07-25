#!/bin/bash

CONTRACTS_DIR="/local/eosnetworkfoundation/downloads"
cleos wallet import --private-key 5JURSKS1BrJ1TagNBw1uVSzTQL2m9eHGkjknWeZkjSt33Awtior
cleos create account eosio evmevmevmevm EOS8kE63z4NcZatvVWY4jxYdtLg6UEA123raMGwS6QDKwpQ69eGcP EOS8kE63z4NcZatvVWY4jxYdtLg6UEA123raMGwS6QDKwpQ69eGcP
cleos set code evmevmevmevm "$CONTRACTS_DIR"/eos-evm/contract/build/evm_runtime/evm_runtime.wasm
cleos set abi evmevmevmevm "$CONTRACTS_DIR"/eos-evm/contract/build/evm_runtime/evm_runtime.abi
cleos push action evmevmevmevm init "{\"chainid\":15555,\"fee_params\":{\"gas_price\":150000000000,\"miner_cut\":10000,\"ingress_bridge_fee\":\"0.0100 EOS\"}}" -p evmevmevmevm
cleos set account permission evmevmevmevm active --add-code -p evmevmevmevm@active
cleos transfer eosio evmevmevmevm "1.0000 EOS" "evmevmevmevm"
# bridging tokens and account balences
cleos transfer eosio evmevmevmevm "1000000.0000 EOS" "0x2787b98fc4e731d0456b3941f0b3fe2e01439961"
# create new account for wrapping trans
MinerAccountPublic=$(grep Public ~/eosio-wallet/anttranwrap1.keys | cut -d: -f2 | sed 's/ //g')
MinerAccountPrivate=$(grep Private ~/eosio-wallet/anttranwrap1.keys | cut -d: -f2 | sed 's/ //g')
cleos create account eosio anttranwrap1 $MinerAccountPublic
cleos wallet import --private-key $MinerAccountPrivate
cleos push action evmevmevmevm open '{"owner":"anttranwrap1"}' -p anttranwrap1
