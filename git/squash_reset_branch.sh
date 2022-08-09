#!/usr/bin/env bash

echo "git reset $(git merge-base main $(git rev-parse --abbrev-ref HEAD)) "
