#!/usr/bin/env bash
# Debug build for the simulator: bin/wellface.prg
source "$(dirname "$0")/common.sh"
compile "$BIN/wellface.prg"
echo "built bin/wellface.prg"
