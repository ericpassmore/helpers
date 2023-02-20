#! /bin/sh

cleos wallet create --file .wallet.pw
cat .wallet.pw | cleos wallet unlock --password
# import main EOSIO account private key
cleos wallet import --private-key 5KQwrPbwdL6PhXujxW37FSSQZ1JiwsST4cqQzDeyXtP79zkvFD3
# create new account
BobPublicKey=$(grep Public ~/eosio-wallet/bob.keys | cut -d: -f2 | sed 's/ //g')
cleos create account eosio bob $BobPublicKey
AlicePublicKey=$(grep Public ~/eosio-wallet/alice.keys | cut -d: -f2 | sed 's/ //g')
cleos create account eosio alice $AlicePublicKey
EricPassmorePublicKey=$(grep Public ~/eosio-wallet/ericpassmore.keys | cut -d: -f2 | sed 's/ //g')
cleos create account eosio ericpassmore $EricPassmorePublicKey
