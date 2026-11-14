#!/usr/bin/env bash
# Runs a timing build (scripts/build-timing.sh) in the simulator in a fixed
# scenario and summarizes its log, unattended. Each load: High Power, heart
# rate from Simulation > Activity Data > Data Simulation, about 21 s awake,
# Always-On 5 s, High Power 5 s, Always-On 4 s; each Always-On prints the
# readings. Drives the simulator's menus by UI scripting, like
# scripts/profile-sim.sh: macOS, the Accessibility permission for the
# terminal, and hands off the mouse and keyboard (about 40 s per load).
#
# Usage: scripts/timing-sim.sh <file.prg> <log file> [loads, default 5]
#   Writes the timing lines to <log file> and prints tools/timing/summary.py's
#   table. The simulator is restarted first.
#
# Exit codes: 0 measured, 2 could not run.
source "$(dirname "$0")/common.sh"

[[ $# -eq 2 || $# -eq 3 ]] || die "usage: scripts/timing-sim.sh <file.prg> <log file> [loads]"
PRG="$1"
LOG="$2"
LOADS="${3:-5}"
[[ -f "$PRG" ]] || die "$PRG not found"
[[ "$(uname)" == "Darwin" ]] || die "driving the simulator by script needs macOS (osascript)"
mkdir -p "$(dirname "$LOG")"
: >"$LOG"

sim() {
    osascript -e 'tell application "System Events" to tell process "simulator"' \
        -e 'set frontmost to true' "$@" -e 'end tell' >/dev/null
}

device_window() {
    echo '(first window whose name starts with "CIQ Simulator")'
}

menu() {   # menu <menu> <item> [<sub item>]
    local item="menu item \"$2\" of menu 1 of menu bar item \"$1\" of menu bar 1"
    [[ $# -eq 3 ]] && item="menu item \"$3\" of menu 1 of $item"
    sim -e "perform action \"AXRaise\" of $(device_window)" -e 'delay 0.5' -e "click $item"
}

# Keep the display awake: with the screen locked or asleep the simulator
# opens no windows and the menus cannot be driven.
caffeinate -d -w $$ &

echo "restarting the simulator"
pkill -f "monkeydo" 2>/dev/null || true
pkill -x simulator 2>/dev/null || true
sleep 2
"$CIQ_SDK/bin/connectiq"
for _ in $(seq 1 30); do
    sim -e "get name of $(device_window)" 2>/dev/null && break
    sleep 1
done
sim -e "get name of $(device_window)" 2>/dev/null || die "the simulator did not start"
sleep 2

pid=""
trap '[[ -n "$pid" ]] && kill "$pid" 2>/dev/null; rm -f "${COMPILE_LOG:-}"' EXIT
for i in $(seq 1 "$LOADS"); do
    echo "load $i of $LOADS"
    # Started in high power, so the first update is a high-power one.
    menu Settings "Display Mode" "High Power"
    "$CIQ_SDK/bin/monkeydo" "$PRG" "$DEVICE" 2>&1 | grep --line-buffered '^timing ' >>"$LOG" &
    pid=$!
    sleep 6
    if [[ $i -eq 1 ]]; then
        # Activity Data is only enabled once an app runs; the setting stays.
        menu Simulation "Activity Data"
        sleep 1
        sim -e 'set dialog to (first window whose name is "")' \
            -e 'click pop up button 1 of dialog' -e 'delay 1' \
            -e 'click menu item "Data Simulation" of menu 1 of pop up button 1 of dialog' -e 'delay 1' \
            -e 'click (first button of dialog whose subrole is "AXCloseButton")' \
            || die "could not set Activity Data to Data Simulation"
    fi
    sleep 15
    menu Settings "Display Mode" "Always-On"
    sleep 5
    menu Settings "Display Mode" "High Power"
    sleep 5
    menu Settings "Display Mode" "Always-On"
    sleep 4
    pkill -f "monkeydo" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
    pid=""
    sleep 2
done

grep -q '^timing ' "$LOG" || die "no timing lines; is $PRG a timing build?"
python3 -I "$ROOT/tools/timing/summary.py" "$LOG"
