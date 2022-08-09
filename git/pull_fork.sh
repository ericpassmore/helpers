#!/usr/bin/env bash

set -x

REPO=${1}
BRANCH=${2}
UPSTREAM=${3:-$REPO}

if [ -z $REPO ] || [ -z $BRANCH ] || [ -z $UPSTREAM ]; then
  echo "Clones a forked repo, sets upstream remote, and creates branch"
  echo "require 3 args REPO and BRANCH and UPSTREAM"
  echo "example: pull_fork.sh ericpassmore/special.git doc-fix-branch bigcompany/special.git"
  exit 1
fi

echo "Going to clone ${REPO} into branch ${BRANCH}"
echo "--> Y to proceed, anything else to stop"
read prompt

if [ "Y" != ${prompt} ]; then
  echo "exiting "
  exit 1
fi

# clone the forked repo
git clone https://github.com/${1}
# change into git repo
DIR=$(basename ${REPO})
DIR=$(echo $DIR | sed 's/\.git$//')

cd $DIR

# don't upstream if repos are the same
if [ $REPO != $UPSTREAM ]; then
  # set upstream to main to sync changes
  echo "Going to add upstream to $UPSTREAM"
  git remote add upstream https://github.com/${UPSTREAM}
  # sync changes
  git pull upstream main
else
  git pull origin main
fi
# change the branch so have multiple choices for changes
git checkout -b $BRANCH
# push up using branch name
git push -u origin $BRANCH
