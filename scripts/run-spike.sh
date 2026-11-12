#!/usr/bin/env bash
# Builds the data spike, starts the simulator and loads it.
# monkeydo stays attached and prints the spike's log; press Ctrl+C to detach.
JUNGLE="$(cd "$(dirname "$0")/.." && pwd)/spikes/data/monkey.jungle"
source "$(dirname "$0")/common.sh"
compile "$BIN/wfspike.prg"
run_in_sim "$BIN/wfspike.prg"
