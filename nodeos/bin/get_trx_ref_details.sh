#!/bin/bash
set -x

FILE=$1

HEAD_BLOCK_NUM=$(cleos get info | grep \"head_block_num\": | cut -d: -f 2 | xargs | sed 's/,//g')
REF_BLOCK_PREFIX=$(cleos get block $HEAD_BLOCK_NUM | grep \"ref_block_prefix\": | cut -d: -f2 | xargs)
sed "s/\"ref_block_num\": 23765,/\"ref_block_num\": ${HEAD_BLOCK_NUM},/" $FILE > /tmp/transaction.json
sed "s/\"ref_block_prefix\": 3788916503,/\"ref_block_num\": ${REF_BLOCK_PREFIX},/" /tmp/transaction.json > $FILE
