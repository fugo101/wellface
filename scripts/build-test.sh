#!/usr/bin/env bash
# Test build (includes the (:test) code): bin/wellface-test.prg
source "$(dirname "$0")/common.sh"
compile "$BIN/wellface-test.prg" -t
echo "built bin/wellface-test.prg"
