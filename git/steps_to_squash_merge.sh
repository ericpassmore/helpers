#!/usr/bin/env bash

TOPIC=${1}
WORKING=${2}
FALSE=1
TRUE=0


########## FUNCTION ###########
branchExists() {
  BRANCH=$1
  if [ -z $BRANCH ]; then
    return $FALSE
  fi
  RM_BRANCH="remotes/origin/${BRANCH}"
  OR_BRANCH="origin/${BRANCH}"
  git rev-parse "${RM_BRANCH}" > /tmp/banchcheck$$.txt 2>&1
  REMOTE_EXIT_CODE=$?
  git rev-parse "${OR_BRANCH}" > /tmp/banchcheck$$.txt 2>&1
  ORIGIN_EXIT_CODE=$?
  # check exit code ; good exit return hash branch exists
  # 128 error can't find branch
  if [ $REMOTE_EXIT_CODE == 0 ] || [ $ORIGIN_EXIT_CODE == 0 ]; then
    return $TRUE
  else
    return $FALSE
  fi
  rm /tmp/banchcheck$$.txt
}

############ MAIN ##############
if [ -z $TOPIC ] || [ -z $WORKING ]; then
  echo "MISSING Args: "
  echo "     must provide TOPIC branch name"
  echo "     must provide WORKING branch name"
  exit 1
fi

if [ $WORKING == "main" ]; then
  echo "ERROR: working branch of main not allowed "
  exit 128
fi


# safety check
if ( ! branchExists ${TOPIC} ) && branchExists ${WORKING} ; then
      ###### SQUASHING INTO NEW BRANCH ########
      echo "git checkout main "
      echo "git reset --hard && git clean -f -d"
      #git checkout main
      #git reset --hard && git clean -f -d

      # switch to new branch
      echo "git checkout -b ${TOPIC}"
      #git checkout -b ${TOPIC}

      # squash WORKING -> TOPIC
      echo "git merge --squash origin/${WORKING}"
      #echo git merge --squash $WORKING

      echo "git commit"
      # git commit

      # publish to remote
      echo "git push origin $TOPIC"
      #git push origin $TOPIC
else
  if ( branchExists ${TOPIC} ) && branchExists ${WORKING} ; then
          ###### SQUASHING INTO NEW BRANCH ########
          echo "git reset --hard && git clean -f -d"
          echo "git checkout ${TOPIC}"
          echo "git pull ${TOPIC}"
          #git reset --hard && git clean -f -d
          #git checkout ${TOPIC}
          #git pull ${TOPIC}


          # squash WORKING -> TOPIC
          echo "git merge --squash origin/${WORKING}"
          #echo git merge --squash $WORKING

          echo "git commit"
          # git commit

          # publish to remote
          echo "git push origin $TOPIC"
          #git push origin $TOPIC
  else
          echo "ERROR: unexpected $WORKING branch does not exist"
          exit 128
  fi
fi
