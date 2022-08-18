#!/usr/bin/env bash

echo "enter remote URL git@github.com:eosnetworkfoundation/mandel.git "
read REMOTE_URL
echo "enter remote name"
read REMOTE_NAME
echo "enter branch"
reach BRANCH

echo "git remote add ${REMOTE_NAME} ${REMOTE_URL} "
echo "git fetch ${REMOTE_NAME} ${BRANCH}:${BRANCH} --no-tags"
echo "git checkout ${BRANCH}"
