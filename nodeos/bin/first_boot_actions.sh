#!/usr/bin/env bash

ENDPOINT=$1
CONTRACT_DIR=$2
PUBLIC_KEY=$3

# ACCOUNTS
cleos --url $ENDPOINT create account eosio eosio.bpay $PUBLIC_KEY
cleos --url $ENDPOINT create account eosio eosio.msig $PUBLIC_KEY
cleos --url $ENDPOINT create account eosio eosio.names $PUBLIC_KEY
cleos --url $ENDPOINT create account eosio eosio.ram $PUBLIC_KEY
cleos --url $ENDPOINT create account eosio eosio.ramfee $PUBLIC_KEY
cleos --url $ENDPOINT create account eosio eosio.saving $PUBLIC_KEY
cleos --url $ENDPOINT create account eosio eosio.stake $PUBLIC_KEY
cleos --url $ENDPOINT create account eosio eosio.token $PUBLIC_KEY
cleos --url $ENDPOINT create account eosio eosio.vpay $PUBLIC_KEY
cleos --url $ENDPOINT create account eosio eosio.rex $PUBLIC_KEY
cleos --url $ENDPOINT create account eosio eosio.wrap $PUBLIC_KEY

# TOKENS $$$
cleos --url $ENDPOINT set contract eosio.token "$CONTRACT_DIR"/eosio.token/
cleos --url $ENDPOINT push action eosio.token create '[ "eosio", "10000000000.0000 EOS" ]' -p eosio.token@active
cleos --url $ENDPOINT push action eosio.token issue '[ "eosio", "1000000000.0000 EOS", "initial issuance" ]' -p eosio

curl --request POST --url "$ENDPOINT"/v1/producer/schedule_protocol_feature_activations -d '{"protocol_features_to_activate": ["0ec7e080177b2c02b278d5088611686b49d739925a92d9bfcacd7fc6b74053bd"]}'
sleep 1

# SECOND CONTRACT
cleos --url $ENDPOINT set contract eosio "$CONTRACT_DIR"/eosio.boot/


echo SKIP NOT RECOGNIZED KV_DATABASE
#cleos push action eosio activate '["825ee6288fb1373eab1b5187ec2f04f6eacb39cb3a97f356a07c91622dd61d16"]' -p eosio

echo ACTION_RETURN_VALUE
cleos --url $ENDPOINT push action eosio activate '["c3a6138c5061cf291310887c0b5c71fcaffeab90d5deb50d3b9e687cead45071"]' -p eosio

echo CONFIGURABLE_WASM_LIMITS2 *
cleos --url $ENDPOINT push action eosio activate '["d528b9f6e9693f45ed277af93474fd473ce7d831dae2180cca35d907bd10cb40"]' -p eosio@active

echo SKIP NOT RECOGNIZED CONFIGURABLE_WASM_LIMITS
#cleos push action eosio activate '["bf61537fd21c61a60e542a5d66c3f6a78da0589336868307f94a82bccea84e88"]' -p eosio

echo BLOCKCHAIN_PARAMETERS
cleos --url $ENDPOINT push action eosio activate '["5443fcf88330c586bc0e5f3dee10e7f63c76c00249c87fe4fbf7f38c082006b4"]' -p eosio

echo GET_SENDER
cleos --url $ENDPOINT push action eosio activate '["f0af56d2c5a48d60a4a5b5c903edfb7db3a736a94ed589d0b797df33ff9d3e1d"]' -p eosio

echo FORWARD_SETCODE
cleos --url $ENDPOINT push action eosio activate '["2652f5f96006294109b3dd0bbde63693f55324af452b799ee137a81a905eed25"]' -p eosio

echo ONLY_BILL_FIRST_AUTHORIZER
cleos --url $ENDPOINT push action eosio activate '["8ba52fe7a3956c5cd3a656a3174b931d3bb2abb45578befc59f283ecd816a405"]' -p eosio

echo RESTRICT_ACTION_TO_SELF
cleos --url $ENDPOINT push action eosio activate '["ad9e3d8f650687709fd68f4b90b41f7d825a365b02c23a636cef88ac2ac00c43"]' -p eosio

echo DISALLOW_EMPTY_PRODUCER_SCHEDULE
cleos --url $ENDPOINT push action eosio activate '["68dcaa34c0517d19666e6b33add67351d8c5f69e999ca1e37931bc410a297428"]' -p eosio

 echo FIX_LINKAUTH_RESTRICTION
cleos --url $ENDPOINT push action eosio activate '["e0fb64b1085cc5538970158d05a009c24e276fb94e1a0bf6a528b48fbc4ff526"]' -p eosio

 echo REPLACE_DEFERRED
cleos --url $ENDPOINT push action eosio activate '["ef43112c6543b88db2283a2e077278c315ae2c84719a8b25f25cc88565fbea99"]' -p eosio

echo NO_DUPLICATE_DEFERRED_ID
cleos --url $ENDPOINT push action eosio activate '["4a90c00d55454dc5b059055ca213579c6ea856967712a56017487886a4d4cc0f"]' -p eosio

echo ONLY_LINK_TO_EXISTING_PERMISSION
cleos --url $ENDPOINT push action eosio activate '["1a99a59d87e06e09ec5b028a9cbb7749b4a5ad8819004365d02dc4379a8b7241"]' -p eosio

echo RAM_RESTRICTIONS
cleos --url $ENDPOINT push action eosio activate '["4e7bf348da00a945489b2a681749eb56f5de00b900014e137ddae39f48f69d67"]' -p eosio

echo WEBAUTHN_KEY
cleos --url $ENDPOINT push action eosio activate '["4fca8bd82bbd181e714e283f83e1b45d95ca5af40fb89ad3977b653c448f78c2"]' -p eosio

echo WTMSIG_BLOCK_SIGNATURES
cleos --url $ENDPOINT push action eosio activate '["299dcb6af692324b899b39f16d5a530a33062804e41f09dc97e9f156b4476707"]' -p eosio

echo GET CODE HASH *
cleos --url $ENDPOINT push action eosio activate '["bcd2a26394b36614fd4894241d3c451ab0f6fd110958c3423073621a70826e99"]' -p eosio@active

echo GET_BLOCK_NUM *
cleos --url $ENDPOINT push action eosio activate '["35c2186cc36f7bb4aeaf4487b36e57039ccf45a9136aa856a5d569ecca55ef2b"]' -p eosio@active

echo CRYPTO_PRIMITIVES *
cleos --url $ENDPOINT push action eosio activate '["6bcb40a24e49c26d0a60513b6aeb8551d264e4717f306b81a37a5afb3b47cedc"]' -p eosio@active

# DISABLE_DEFERRED_TRXS_STAGE_1 - DISALLOW NEW DEFERRED TRANSACTIONS
#cleos --url $ENDPOINT push action eosio activate '["fce57d2331667353a0eac6b4209b67b843a7262a848af0a49a6e2fa9f6584eb4"]' -p eosio@active

# DISABLE_DEFERRED_TRXS_STAGE_2 - PREVENT PREVIOUSLY SCHEDULED DEFERRED TRANSACTIONS FROM REACHING OTHER NODE
# THIS DEPENDS ON DISABLE_DEFERRED_TRXS_STAGE_1
#cleos --url $ENDPOINT push action eosio activate '["09e86cb0accf8d81c9e85d34bea4b925ae936626d00c984e4691186891f5bc16"]' -p eosio@active

# INSTANT_FINALITY
#cleos push action eosio activate '["8cb6dd1e5607208331eb5983141e159c75a597413887e80e8a9a4b715a507eb7"]' -p eosio@active

sleep 1;

#cleos set contract eosio "$CONTRACT_DIR"/eosio.msig
#sleep 1;
cleos --url $ENDPOINT set contract eosio "$CONTRACT_DIR"/eosio.bios
sleep 1;
cleos --url $ENDPOINT set contract eosio "$CONTRACT_DIR"/eosio.system
sleep 1;
cleos --url $ENDPOINT set contract eosio "$CONTRACT_DIR"/eosio.wrap
sleep 1;
