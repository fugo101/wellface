#!/usr/bin/env bash
# Builds the test PRG, starts the simulator and runs the unit tests in it.
# Pass/fail comes from the log, never from monkeydo's exit code: in SDK 9.3.0
# `monkeydo -t` exits 1 even when every test passes.
#
# Exit codes: 0 all tests passed, 1 a test failed, 2 the tests could not run
# (build failed, simulator not reachable, crash or timeout).
# Optional argument: one test to run (for example FaceModelTest.someTest).
source "$(dirname "$0")/common.sh"
trap 'exit 2' ERR

compile "$BIN/wellface-test.prg" -t

LOG="$BIN/test.log"
# Start the simulator hidden and in the background (or leave a running one
# as it is): the tests need no window. Set CIQ_SIM_SHOW=1 to show it.
if [[ "$(uname)" == "Darwin" && -z "${CIQ_SIM_SHOW:-}" ]]; then
    open -g -j -a "$CIQ_SDK/bin/ConnectIQ.app"
else
    "$CIQ_SDK/bin/connectiq"   # starts the simulator, or focuses it if running
fi

# Run with a hard time limit (macOS has no `timeout`).
with_timeout() { perl -e 'alarm shift; exec @ARGV' "$@"; }

for _ in $(seq 1 30); do
    with_timeout 300 "$CIQ_SDK/bin/monkeydo" "$BIN/wellface-test.prg" "$DEVICE" -t "$@" 2>&1 \
        | mask_key >"$LOG" || true
    grep -q "Unable to connect to simulator" "$LOG" || break
    sleep 2
done
cat "$LOG"

if ! grep -q "^RESULTS" "$LOG"; then
    die "no RESULTS block in the test output (simulator not reachable, crash or timeout); see bin/test.log"
fi
ran="$(sed -n 's/^Ran \([0-9][0-9]*\) test.*/\1/p' "$LOG" | tail -1)"
if grep -q "^PASSED" "$LOG" && ! grep -q "^FAILED" "$LOG" && [[ "${ran:-0}" -gt 0 ]]; then
    echo "tests passed ($ran)"
    exit 0
fi
echo "tests FAILED" >&2
exit 1
