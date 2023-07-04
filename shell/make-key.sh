#!/usr/bin/env bash

FILENAME=$1
EMAIL=$2
HOSTNAME=$3

ssh-keygen -t ed25519 -f ~/.ssh/"${FILENAME}".key -C "${EMAIL} - ${HOSTNAME}"
