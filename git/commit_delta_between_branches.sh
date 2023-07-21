#!/usr/bin/env bash

HELP(){
  echo "Script to view deltas between two branches in git. This will show the commits and would be merged, along with the names of the altered files."
  echo "This script does not modify anything. It assumes branches on same remote named origin"
  echo "This script checks if you are in a local git repository. If you are not this script will create a working directory to perform the work. Once the script successfully finsished the working directory will be cleaned up"
  echo ""
  echo "view_commit_delta_between_branch.sh -i merge-into -f merge-from [-r git-owner/git-repository]"
  echo "    -i : name of tag or branch we intend to merge into"
  echo "    -f : name of tag or branch we want to pull commits from"
  echo "    -r : name of git repository to compare, not required if running from local git repository"
  echo "    -v : verbose mode"
  exit
}

while getopts "vi:f:r:" option; do
   case $option in
    i) # set build dir
      BRANCH_TO_MERGE_INTO=${OPTARG}
      ;;
    f) # set branch
      BRANCH_TO_MERGE_FROM=${OPTARG}
      ;;
    r) # repository
      GIT_REPO=https://github.com/"${OPTARG}".git
      ;;
    v) # verbose ; setting to space prevents default
      MODE="verbose"
      ;;
    c) # count lines; shows diff with line count
      COUNT=1
      ;;
    :) # no args
      HELP;
      ;;
    *) # abnormal args
      HELP;
      ;;
   esac
done
# check for required args
if [ -z "$BRANCH_TO_MERGE_INTO" ] || [ -z "$BRANCH_TO_MERGE_FROM" ]; then
  echo "Missing required arguments -i merge-into -f merge-from"
  HELP;
fi

if [ "$MODE" == "verbose" ]; then MODE=""
else MODE="--quiet";
fi
if [ -z "$COUNT" ] || [ "$COUNT" != 1 ]; then COUNT=0
fi


CLEAN_EXIT() {
  cd ../
  [ -d "$WORKING_DIR" ] && rm -rf "$WORKING_DIR"
  exit 128
}

GIT_SETUP() {
  # git is sensitive , requires special treatment for quiet/verbose
  if [ -n "$MODE" ]; then
    git init "$MODE" && git remote add origin "${GIT_REPO}" \
         && git fetch "${MODE}" --no-tags origin "$BRANCH_TO_MERGE_INTO" \
         && git fetch "${MODE}" --no-tags origin "$BRANCH_TO_MERGE_FROM" \
         || CLEAN_EXIT
  else
    echo -e '\033[1mVERBOSE MODE\033[0m'
    git init && git remote add origin "${GIT_REPO}" \
         && git fetch --no-tags origin "$BRANCH_TO_MERGE_INTO" \
         && git fetch --no-tags origin "$BRANCH_TO_MERGE_FROM" \
         || CLEAN_EXIT
  fi
}

COMPARE() {
  echo -e '\033[1mGIT LOGS\033[0m'
  # compare command NOTE two dot
  git log --oneline origin/"$BRANCH_TO_MERGE_INTO"..origin/"$BRANCH_TO_MERGE_FROM" | cat
  echo -e '\033[1mFILES CHANGED\033[0m'
  # show files NOTE three dots
  if [ ! $COUNT ]; then
    git diff --name-only origin/"$BRANCH_TO_MERGE_INTO"...origin/"$BRANCH_TO_MERGE_FROM" | cat
  else
    git diff --unified=0 origin/release/3.1...origin/release/4.0 | egrep -e '^@@' -e '^--' -e '^\+\+' | awk 'BEGIN {count=0} /^\@\@/ {count++} /^\+\+/ {printf "%d %s\n", count, $0; count=0}' | sort -rn
  fi
}

# shellcheck disable=SC2046
if git status >>/dev/null 2>&1; then
  if [ $(git remote -v | grep "$GIT_REPO" | wc -l) -ge 1 ]; then
    COMPARE "$BRANCH_TO_MERGE_INTO" "$BRANCH_TO_MERGE_FROM"
  else
    echo "Local repository does not match git remote $GIT_REPO"
    echo "please enter correct local repository"
    exit 128
  fi
else
  if git ls-remote "$GIT_REPO" >>/dev/null 2>&1 ; then
    WORKING_DIR=working_dir_"$$"
    mkdir "$WORKING_DIR" && cd "$WORKING_DIR" || CLEAN_EXIT

    GIT_SETUP

    COMPARE "$BRANCH_TO_MERGE_INTO" "$BRANCH_TO_MERGE_FROM"
    cd .. && rm -rf "$WORKING_DIR" || exit 128
  else
    echo "Provided git repository is not valid"
    exit 128
  fi
fi
