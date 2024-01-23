#!/usr/bin/env bash

DIR=$1
INCLUDE_THIS_MONTH=${2:-N}
SHOW_TOP=${3:-20}

CURRENT_MONTH=$(date +%m)
CURRENT_YEAR=$(date +%Y)

MONTHS_PADDING=12
if [ $INCLUDE_THIS_MONTH == "Y" ]; then
    MONTHS_PADDING=13
fi
QUERY_DATES=()

# loop back to get the last 9 months
# 10 months because we need start and end dates
# for example from 9th - 10th
#             from 8th - 9th
#                  .........
#             from 1st - 2nd
for i in {1..10}; do

    # Calculate the month number
    # need to add MONTHS_PADDING to ensure no negative numbers
    not_normalized_month=$((CURRENT_MONTH - i + ${MONTHS_PADDING}))
    # normalize by modulos 12 months
    MONTH=$(( $not_normalized_month % 12 + 1 ))
    # pre-nomalization of 11 + 1 is Dec
    # that means we when back to prev year
    # we need to adjus accordingly
    if [ $not_normalized_month -eq 11 ]; then
        CURRENT_YEAR=$((CURRENT_YEAR - 1))
    fi

    # push into array
    QUERY_DATES+=("${CURRENT_YEAR}-${MONTH}-01")
done

cd $DIR  || exit
[ -f /tmp/month_file_commits.txt ] && rm /tmp/month_file_commits.txt
touch /tmp/month_file_commits.txt || exit
for i in {1..9}; do
  echo "git log --since \"${QUERY_DATES[i]}\" --until \"${QUERY_DATES[i-1]}\" --oneline --no-merges"
  git log --since \"${QUERY_DATES[i]}\" --until \"${QUERY_DATES[i-1]}\" --oneline --no-merges | while IFS= read -r line
  do
    SHA=$(echo "$line" | cut -d" " -f1)
    # tail skips first 7 lines, they are always headers
    # between the headers and file lis is sometimes a multi-line comment
    # last grep filters to files they either contain a '.' or an '/'
    git show --name-only ${SHA} | tail -n +7 | grep '\.\|/' >> /tmp/month_file_commits.txt
  done
  echo "${QUERY_DATES[i]}"
  echo "-----------------"
  sort /tmp/month_file_commits.txt | grep '.' | uniq -c | sort -rn | head -${SHOW_TOP}
  rm /tmp/month_file_commits.txt
done
