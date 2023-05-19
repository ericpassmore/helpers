#! /usr/bin/env bash

#cleos wallet create --file .wallet.pw
cleos wallet open
cat .wallet.pw | cleos wallet unlock --password
# import main EOSIO account private key
#cleos wallet import --private-key 5KQwrPbwdL6PhXujxW37FSSQZ1JiwsST4cqQzDeyXtP79zkvFD3
# create system accounts
EOSTokenPublicKey=$(grep Public ~/eosio-wallet/eosio.token.keys | cut -d: -f2 | sed 's/ //g')
cleos create account eosio eosio.token $EOSTokenPublicKey
EOSSystemPublicKey=$(grep Public ~/eosio-wallet/eosio.system.keys | cut -d: -f2 | sed 's/ //g')
cleos create account eosio eosio.system $EOSSystemPublicKey
# create new account
BobPublicKey=$(grep Public ~/eosio-wallet/bob.keys | cut -d: -f2 | sed 's/ //g')
cleos create account eosio bob $BobPublicKey
AlicePublicKey=$(grep Public ~/eosio-wallet/alice.keys | cut -d: -f2 | sed 's/ //g')
cleos create account eosio alice $AlicePublicKey
EricPassmorePublicKey=$(grep Public ~/eosio-wallet/ericpassmore.keys | cut -d: -f2 | sed 's/ //g')
cleos create account eosio ericpassmore $EricPassmorePublicKey
HokiesPublicKey=$(grep Public ~/eosio-wallet/hokieshokies.keys | cut -d: -f2 | sed 's/ //g')
# --max-cpu-usage-ms 2866 --max-net-usage 15416
cleos create account eosio hokieshokies $HokiesPublicKey
AliceLionPublicKey=$(grep Public ~/eosio-wallet/alicetestlio.keys | cut -d: -f2 | sed 's/ //g')
cleos create account  eosio alicetestlio $AliceLionPublicKey
