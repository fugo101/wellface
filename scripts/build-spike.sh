#!/usr/bin/env bash
# Data spike (ticket 02), a separate debug-only face: bin/wfspike.prg
# Copy that file to GARMIN/APPS to wear it; it shows up as its own face.
# A short name, because its on-watch log must be GARMIN/APPS/LOGS/WFSPIKE.TXT.
JUNGLE="$(cd "$(dirname "$0")/.." && pwd)/spikes/data/monkey.jungle"
source "$(dirname "$0")/common.sh"
compile "$BIN/wfspike.prg"
echo "built bin/wfspike.prg"
