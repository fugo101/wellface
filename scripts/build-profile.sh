#!/usr/bin/env bash
# Profile build: the release build with profiling support (-k), so the
# simulator's profiler (and, on the watch, a .PRF log) can time it.
# bin/wellface-profile.prg; see docs/build.md, "Profile".
source "$(dirname "$0")/common.sh"
compile "$BIN/wellface-profile.prg" -r -k
echo "built bin/wellface-profile.prg"
