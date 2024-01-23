#!/usr/bin/env bash

DIR=$1
EARLIEST_COMMIT=0aff4619cd8caf8c8d5d24890ebef0aea0992f10
EARLIEST_COMMIT=$(echo $EARLIEST_COMMIT | cut -c1-9)

cd $DIR  || exit
git log --oneline ${EARLIEST_COMMIT}..HEAD | while IFS= read -r line
do
  SHA=$(echo "$line" | cut -d" " -f1)
  AUTHOR=$(git show ${SHA} --shortstat | grep Author | cut -d: -f2 | cut -d" " -f2)
  DELTA=$(git show ${SHA} --shortstat | tail -1 | cut -d" " -f2,5,7 | tr " " ",")
  echo "${AUTHOR},${DELTA}" >> /tmp/who_commits.txt
done

for auth in $(cat /tmp/who_commits.txt | cut -d, -f1 | sort -u)
do
  total_commits=0
  for i in $(grep "$auth" /tmp/who_commits.txt | sort | cut -d, -f3)
  do
    let total_commits=total_commits+1
  done
  total_ins=0
  for i in $(grep "$auth" /tmp/who_commits.txt | sort | cut -d, -f3)
  do
    let total_ins=total_ins+i
  done
  total_files=0
  for i in $(grep "$auth" /tmp/who_commits.txt | sort | cut -d, -f2)
  do
    let total_files=total_files+i
  done
  echo "${auth} commits: ${total_commits} files: ${total_files} lines inserted: ${total_ins}"
done

rm /tmp/who_commits.txt
