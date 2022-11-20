#!/usr/bin/env bash

FILENAME=$1
HOSTNAME=$2

ssh-keygen -t ed25519 -f ~/.ssh/$FILENAME.key -C "first.last@eosnetwork.com - $HOSTNAME"
