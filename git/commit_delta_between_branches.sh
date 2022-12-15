#!/usr/bin/env bash

HELP(){
  echo "Script to view deltas between two branches. This will show the commits and would be merged, along with the names of the altered files."
  echo "This script does not modify anything"
  echo "This script checks if you are in a local git repository. If you are not this script will create a working directory to perform the work. Once the script successfully finsished the working directory will be cleaned up"
  echo ""
  echo "view_commit_delta_between_branch.sh -i merge-into -f merge-from [-r git-owner/git-repository]"
  echo "    -i : name of tag or branch we intend to merge into"
  echo "    -f : name of tag or branch we want to pull commits from"
  echo "    -r : name of git repository to compare, not required if running from local git repository"
  exit
}

while getopts "i:f:r:" option; do
   case $option in
    i) # set build dir
      BRANCH_TO_MERGE_INTO=${OPTARG}
      ;;
    f) # set branch
      BRANCH_TO_MERGE_FROM=${OPTARG}
      ;;
    r) # repository
      GIT_REPO=${OPTARG}
      ;;
    :) # no args
      Help;
      ;;
    *) # abnormal args
      Help;
      ;;
   esac
done
# check for required args
if [ -z "$BRANCH_TO_MERGE_INTO" ] || [ -z "$BRANCH_TO_MERGE_FROM" ]; then
  echo "Missing required arguments -i merge-into -f merge-from"
  HELP;
fi

COMPARE() {
  # compare command NOTE two dot
  git log --oneline origin/"$BRANCH_TO_MERGE_INTO"..origin/"$BRANCH_TO_MERGE_FROM" | cat
  # show files NOTE three dots
  git diff --name-only origin/"$BRANCH_TO_MERGE_INTO"...origin/"$BRANCH_TO_MERGE_FROM" | cat
}

set -x
# shellcheck disable=SC2046
if git status >>/dev/null ; then
  if [ $(git remote -v | grep "$GIT_REPO" | wc -l) -ge 1 ]; then
    COMPARE "$BRANCH_TO_MERGE_INTO" "$BRANCH_TO_MERGE_FROM"
  else
    echo "Local repository does not match git remote $GIT_REPO"
    echo "please enter correct local repository"
    exit 128
  fi
else
  if git ls-remote "$GIT_REPO" ; then
    WORKING_DIR=working_dir_"$$"
    mkdir "$WORKING_DIR" && cd "$WORKING_DIR" && git clone "${GIT_REPO}" || exit
    COMPARE "$BRANCH_TO_MERGE_INTO" "$BRANCH_TO_MERGE_FROM"
    cd .. && rm -rf "$WORKING_DIR" || exit
  else
    echo "Provided git repository is not valid"
    exit 128
  fi
fi
