#!/usr/bin/env bash

echo "local delete "
echo "git branch -d origin/${1}"
echo "remote delete"
echo "git push origin --delete ${1}"
