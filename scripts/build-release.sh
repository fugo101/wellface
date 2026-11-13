#!/usr/bin/env bash
# Release build for sideloading: bin/wellface-release.prg
# scripts/sideload.sh builds it and copies it to the watch.
source "$(dirname "$0")/common.sh"
compile "$BIN/wellface-release.prg" -r --build-stats 0
echo "built bin/wellface-release.prg"
