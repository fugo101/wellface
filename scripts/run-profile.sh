#!/usr/bin/env bash
# Profile build (unless a PRG is given), then starts the simulator and loads
# it there; the simulator opens its profiler for a build with profiling
# support. See docs/build.md, "Profile", for the measurement scenario.
# monkeydo stays attached and prints the face's log; press Ctrl+C to detach.
#
# Usage: scripts/run-profile.sh [file.prg]
source "$(dirname "$0")/common.sh"
if [[ $# -gt 1 ]]; then
    die "usage: scripts/run-profile.sh [file.prg]"
elif [[ $# -eq 1 ]]; then
    PRG="$1"
    [[ -f "$PRG" ]] || die "$PRG not found"
else
    "$ROOT/scripts/build-profile.sh" || die "profile build failed"
    PRG="$BIN/wellface-profile.prg"
fi
run_in_sim "$PRG"
