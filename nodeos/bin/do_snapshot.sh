#!/usr/bin/env bash

ENDPOINT=${1:-127.0.0.1:8888}

SNAPSHOT_DIR="/bigata1/nodeos/data/snapshots"
curl -X POST http://${ENDPOINT}/v1/producer/create_snapshot > ${SNAPSHOT_DIR}/snapshot.json

SNAP_PATH=$(jq .snapshot_name /bigata1/nodeos/data/snapshots/snapshot.json | sed 's/"//g')
SNAP_HEAD_BLOCK=$(jq .head_block_num /bigata1/nodeos/data/snapshots/snapshot.json)
VERSION=$(jq .version /bigata1/nodeos/data/snapshots/snapshot.json)
HEAD_BLOCK_TIME=$(jq .head_block_time /bigata1/nodeos/data/snapshots/snapshot.json | sed 's/"//g')


DATE=${HEAD_BLOCK_TIME%T*}
TIME=${HEAD_BLOCK_TIME#*T}
HOUR=${TIME%%:*}
DATE="${DATE}-${HOUR}"
if type zstd >/dev/null 2>&1; then
  # rename to our format snapshot-2019-08-11-16-eos-v6-0073487941.bin.zst
  NEW_PATH="${SNAP_PATH%/*}/snapshot-${DATE}-eos-v${VERSION}-${SNAP_HEAD_BLOCK}.bin.zst"
  zstd < "$SNAP_PATH" > "$NEW_PATH"
  if [ $? -eq 0 ]; then
    rm "$SNAP_PATH"
  fi
else
  NEW_PATH="${SNAP_PATH%/*}/snapshot-${DATE}-eos-v${VERSION}-${SNAP_HEAD_BLOCK}.bin.gzip"
  gzip < "$SNAP_PATH" > "$NEW_PATH"
  if [ $? -eq 0 ]; then
    rm "$SNAP_PATH"
  fi
fi
rm ${SNAPSHOT_DIR}/snapshot.json
