#!/usr/bin/env bash

START=$(date +%s.%N)
NPROC=8
TUID=$(id -ur)

TEMPS=$(~/scripts/get_temp.sh)

# must not be root to run
if [ "$TUID" -eq 0 ]; then
  echo "Trying to run as root user exiting"
  exit
fi

NODEOS_CONFIG=/local/eosnetworkfoundation/bin/nodeos_config.sh
if [ -f "$NODEOS_CONFIG" ]; then
  source "$NODEOS_CONFIG"
else
  echo "Cannot find ${NODEOS_CONFIG}"
  exit
fi
cd "${LEAP_GIT_DIR:?}" || exit

TODAY=$(date -u +%F)
git pull
git submodule update --init --recursive

[ ! -d "$LEAP_BUILD_DIR" ] && mkdir -p "$LEAP_BUILD_DIR"
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH=/usr/lib/llvm-11 "$LEAP_BUILD_DIR" >> "$LOG_DIR"/nodeos_nightly_build_"${TODAY}".log 2>&1
cd "$LEAP_BUILD_DIR" || exit
make -j "${NPROC}" package >> "$LOG_DIR"/nodeos_nightly_build_"${TODAY}".log 2>&1
END=$(date +%s.%N)

WALL_CLOCK_SEC=$(echo $END - $START | bc)
echo "${TODAY} NODEOS BUILD TOOK ${WALL_CLOCK_SEC} secs with PROC ${NPROC} ${TEMPS}" >> "$LOG_DIR"/nodeos_nightly_build_times.log 
