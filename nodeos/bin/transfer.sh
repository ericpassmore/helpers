# create a new waller
cleos wallet create -n session11 -f session11_w
# get wallet password
PASSWORD=$(cat session11_w)
# add active key 
cleos wallet import -n session11 --private-key 5JvmRevRNdmLEc6anvB8SuwGDeTmxvivjWsuGD1KJQrcYZWac4t
# open wallet
echo $PASSWORD | cleos wallet open -n session11
echo $PASSWORD | cleos wallet unlock -n session11
# check keys in wallet
cleos wallet keys
# transfer from enfsession11 to enfsession22
cleos -u https://jungle4.cryptolions.io:443 push action eosio.token transfer '[ "enfsession11", "enfsession22", "25.0000 JUNGLE", "m" ]' -p enfsession11@active
cleos -u https://jungle4.cryptolions.io:443 push action eosio.token transfer '[ "enfsession11", "enfsession22", "1.2000 EOS", "m" ]' -p enfsession11@active
