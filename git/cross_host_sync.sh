#!/usr/bin/env bash

IP=${1:-"127.0.0.1"}
if [ "$IP" == "127.0.0.1" ]; then echo "BAD CLIENT IP RESET"; exit; fi

echo "please choose an org ENF, Wharf, Antelope, EHP"
read ORGANIZATION

case $ORGANIZATION in
  ehp)
    GIT_ORG="ericpassmore"
    DIR=$GIT_ORG
    ;;
  wharf)
    GIT_ORG="wharfkit"
    DIR="wharf"
    ;;
  antelope)
    GIT_ORG="antelopeIO"
    DIR="antelope"
    ;;
  enf)
    GIT_ORG="eosnetworkfoundation"
    DIR="ENF"
    ;;
  *)
    echo "option not valid"; exit 1;
    ;;
esac
echo "please choose a repo"
ROOT_DIR="/local/eosnetworkfoundation/repos"
cd "${ROOT_DIR:?}/$DIR" || exit
ls -1
read REPO
cd "${REPO:?}" || exit
echo "enter branch to sync"
git branch -a
read BRANCH
git pull origin "$BRANCH" || exit
