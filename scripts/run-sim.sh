#!/usr/bin/env bash
# Debug build, then starts the simulator and loads the face into it.
# monkeydo stays attached and prints the face's log; press Ctrl+C to detach.
source "$(dirname "$0")/common.sh"
compile "$BIN/wellface.prg"
"$CIQ_SDK/bin/connectiq"   # starts the simulator, or focuses it if running

out="$(mktemp)"
trap 'rm -f "$out"' EXIT
for _ in $(seq 1 30); do
    status=0
    "$CIQ_SDK/bin/monkeydo" "$BIN/wellface.prg" "$DEVICE" 2>&1 | mask_key | tee "$out" || status=$?
    grep -q "Unable to connect to simulator" "$out" || exit "$status"
    sleep 2   # the simulator is still starting
done
die "could not reach the simulator"
