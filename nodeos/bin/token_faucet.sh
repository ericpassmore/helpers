#! /usr/bin/env bash

cleos wallet create --file .wallet.pw
cat .wallet.pw | cleos wallet unlock --password
####
# add the contract
# cleos set contract eosio.token /local/eosnetworkfoundation/repos/ENF/eos-system-contracts/build/contracts/eosio.token --abi eosio.token.abi -p eosio.token@active
#
# import eosio.token perms
EOSTokenPrivateKey=$(grep Private ~/eosio-wallet/eosio.token.keys | cut -d: -f2 | sed 's/ //g')
cleos wallet import --private-key $EOSTokenPrivateKey
# mint SYS tokens
# cleos push action eosio.token create '[ "eosio", "1000000000.0000 SYS"]' -p eosio.token@active
# mint EOS tokens
# cleos push action eosio.token create '[ "eosio", "1000000000.0000 EOS"]' -p eosio.token@active
# put some SYS tokens into circulation only to eosio user
cleos push action eosio.token issue '[ "eosio", "10000.0000 SYS", "first" ]' -p eosio@active
# transfer SYS tokens to user
cleos push action eosio.token transfer '[ "eosio", "bob", "100.0000 SYS", "second transfer" ]' -p eosio@active
cleos push action eosio.token transfer '[ "eosio", "ericpassmore", "100.0000 SYS", "second transfer" ]' -p eosio@active
cleos push action eosio.token transfer '[ "eosio", "alice", "100.0000 SYS", "second transfer" ]' -p eosio@active
# put some EOS tokens in circulation only to eosio user
cleos push action eosio.token issue '[ "eosio", "10000.0000 EOS", "first" ]' -p eosio@active
# transfer EOS tokens to user
cleos push action eosio.token transfer '[ "eosio", "bob", "25.0000 EOS", "second transfer" ]' -p eosio@active
