#!/usr/bin/env bash
# Timing build: the release build with the (:timing) code built in
# (timing.jungle), which records the face's update times with
# System.getTimer and prints them when the screen sleeps or the face is
# hidden or stopped. bin/wellface-timing.prg; see docs/build.md,
# "Timing build".
source "$(dirname "$0")/common.sh"
JUNGLE="$ROOT/monkey.jungle;$ROOT/timing.jungle"
compile "$BIN/wellface-timing.prg" -r --build-stats 0
echo "built bin/wellface-timing.prg"
