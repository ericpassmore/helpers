#!/usr/bin/env bash

SUBNET=${1}
DEST_SWITCH=${2}
DEFAULT_MASK=255.255.255.0

if [ -z $SUBNET ]; then
  echo "Must provide subnet as first arg and destination switch as second arg"
  exit 1
fi

# select the interfact
networksetup -listnetworkserviceorder
echo "Enter the name of the network example \'Wi-Fi\'"
read -p "Network Name: " NETWORK

if [ $SUBNET == "clear" ]; then
  # no routes clears it out
  networksetup -setadditionalroutes
  exit 0
fi
if [ -z $DEST_SWITCH ]; then
  echo "when providing subnet must provide destination switch as second arg"
  exit 1
fi

echo "Adding $NETWORK $SUBNET $DEFAULT_MASK $DEST_SWITCH "
list=""
for l in $(networksetup -getadditionalroutes "$NETWORK")
do
  list="${list} ${l}"
done
list="${list} $SUBNET $DEFAULT_MASK $DEST_SWITCH"
networksetup -setadditionalroutes "$NETWORK" "$list"
