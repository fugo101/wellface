#!/usr/bin/env bash
# Debug build, then starts the simulator and loads the face into it.
# monkeydo stays attached and prints the face's log; press Ctrl+C to detach.
source "$(dirname "$0")/common.sh"
compile "$BIN/wellface.prg"
run_in_sim "$BIN/wellface.prg"
