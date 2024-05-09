#!/usr/bin/env bash

ENDPOINT=${1:-127.0.0.1:8888}

SNAPSHOT_DIR="/bigata1/"
curl -X POST http://${ENDPOINT}/v1/producer/create_snapshot > ${SNAPSHOT_DIR}/snapshot.json
SNAP_PATH=$(cat "${SNAPSHOT_DIR}/snapshot.json" | \
  python3 -c "import sys
import json
print (json.load(sys.stdin)['snapshot_name'])")
SNAP_HEAD_BLOCK=$(cat "${SNAPSHOT_DIR}/snapshot.json" | \
  python3 -c "import sys
import json
print (json.load(sys.stdin)['head_block_num'])")
VERSION=$(cat "${SNAPSHOT_DIR}/snapshot.json" | \
  python3 -c "import sys
import json
print (json.load(sys.stdin)['version'])")
HEAD_BLOCK_TIME=$(cat "${SNAPSHOT_DIR}/snapshot.json" | \
  python3 -c "import sys
import json
print (json.load(sys.stdin)['head_block_time'])")

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
