#! /usr/bin/env bash

cat .wallet.pw | cleos wallet unlock --password
# transfer EOS tokens to hokieshokies
cleos push action eosio.token transfer '[ "eosio", "hokieshokies", "5.0000 SYS", "may 2023 transfer sys" ]' -p eosio@active
cleos push action eosio.token transfer '[ "eosio", "hokieshokies", "5.0000 EOS", "may 2023 transfer eos" ]' -p eosio@active
# transfer EOS token to alicetestlio
cleos push action eosio.token transfer '[ "eosio", "alicetestlio", "5.0000 SYS", "may 2023 transfer sys" ]' -p eosio@active
cleos push action eosio.token transfer '[ "eosio", "alicetestlio", "5.0000 EOS", "may 2023 transfer eos" ]' -p eosio@active
# print new balences
cleos get currency balance eosio.token hokieshokies EOS
cleos get currency balance eosio.token alicetestlio EOS
