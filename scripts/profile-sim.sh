#!/usr/bin/env bash
# Runs the fixed profiling scenario of the settings-ready spec in the
# simulator and reads the result: the default face, heart rate changing every
# second (Simulation > Activity Data > Data Simulation), 30 s in high power,
# then 3 minutes in Always On. Drives the simulator's menus by UI scripting,
# so it needs macOS and the Accessibility permission for the terminal; do not
# use the mouse or keyboard while it runs (about 4 minutes).
#
# Usage: scripts/profile-sim.sh <file.prg> <out dir> [run name]
#   The PRG must be a build with profiling support (scripts/build-profile.sh)
#   and have its .prg.debug.xml next to it. Writes <out dir>/<run>.PRF (the
#   profiler's own log), <run>.txt (tools/profile/prf.py's table) and
#   <run>-memory.txt (the memory viewer's figures). The simulator is
#   restarted first.
#
# Exit codes: 0 measured, 2 could not run.
source "$(dirname "$0")/common.sh"

[[ $# -eq 2 || $# -eq 3 ]] || die "usage: scripts/profile-sim.sh <file.prg> <out dir> [run name]"
PRG="$1"
OUT="$2"
RUN="${3:-$(basename "$PRG" .prg)}"
DEBUG_XML="$PRG.debug.xml"
[[ -f "$PRG" ]] || die "$PRG not found"
[[ -f "$DEBUG_XML" ]] || die "$DEBUG_XML not found"
[[ "$(uname)" == "Darwin" ]] || die "profiling by script needs macOS (osascript)"
mkdir -p "$OUT"
LOGS="${TMPDIR%/}/com.garmin.connectiq/GARMIN/APPS/LOGS"
AWAKE=30
ALWAYS_ON=180

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

# A real mouse click on a button: the profiler ignores accessibility clicks.
click_button() {   # click_button <window> <button>
    local point
    point="$(osascript -e 'tell application "System Events" to tell process "simulator"' \
        -e 'set frontmost to true' -e "perform action \"AXRaise\" of window \"$1\"" \
        -e "set {px, py} to position of button \"$2\" of window \"$1\"" \
        -e "set {sx, sy} to size of button \"$2\" of window \"$1\"" \
        -e 'return ((px + sx / 2) as integer as text) & "," & ((py + sy / 2) as integer as text)' \
        -e 'end tell')" || die "no button $2 in window $1"
    sleep 0.5
    osascript -l JavaScript -e "
        ObjC.import('CoreGraphics');
        const p = \$.CGPointMake($point);
        for (const t of [\$.kCGEventMouseMoved, \$.kCGEventLeftMouseDown, \$.kCGEventLeftMouseUp]) {
            \$.CGEventPost(\$.kCGHIDEventTap, \$.CGEventCreateMouseEvent(null, t, p, \$.kCGMouseButtonLeft));
            delay(0.1);
        }" >/dev/null
}

static_texts() {   # static_texts <window>
    osascript -e "tell application \"System Events\" to tell process \"simulator\" to get value of every static text of window \"$1\"" 2>/dev/null
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
sleep 2

started="$(mktemp)"
echo "loading $PRG; the profiler starts with it"
"$CIQ_SDK/bin/monkeydo" "$PRG" "$DEVICE" >/dev/null 2>&1 &
pid=$!
disown "$pid" 2>/dev/null || true
trap 'kill "$pid" 2>/dev/null || true; rm -f "$started" "${COMPILE_LOG:-}"' EXIT
for _ in $(seq 1 30); do
    sim -e 'get name of window "Profiler"' 2>/dev/null && break
    sleep 1
done
sim -e 'get name of window "Profiler"' 2>/dev/null || die "the profiler did not open (is $PRG built with -k?)"

# Activity Data is only enabled once an app runs.
echo "high power, heart rate from Data Simulation"
menu Settings "Display Mode" "High Power"
menu Simulation "Activity Data"
sleep 1
sim -e 'set dialog to (first window whose name is "")' \
    -e 'click pop up button 1 of dialog' -e 'delay 1' \
    -e 'click menu item "Data Simulation" of menu 1 of pop up button 1 of dialog' -e 'delay 1' \
    -e 'click (first button of dialog whose subrole is "AXCloseButton")' \
    || die "could not set Activity Data to Data Simulation"

echo "awake for $AWAKE s"
sleep "$AWAKE"
echo "Always On for $ALWAYS_ON s"
menu Settings "Display Mode" "Always-On"
sleep "$ALWAYS_ON"

menu File "View Memory"
sleep 2
static_texts "Active Memory" | tr ',' '\n' | sed 's/^ //' | grep -E "Memory|Objects" >"$OUT/$RUN-memory.txt" || true

echo "stopping the profiler"
click_button Profiler Stop
sleep 3
# A stale debug-file name can make the profiler window complain; the log is
# read below with this build's own debug file, so dismiss it.
sim -e 'set extra to (every window whose name is not "Profiler" and name is not "Active Memory" and name does not start with "CIQ Simulator")' \
    -e 'if (count of extra) > 0 then key code 53' 2>/dev/null || true

prf="$(find "$LOGS" -name '*.PRF' -newer "$started" 2>/dev/null | head -1)"
[[ -n "$prf" ]] || die "the profiler wrote no .PRF log"
cp "$prf" "$OUT/$RUN.PRF"
python3 -I "$ROOT/tools/profile/prf.py" "$OUT/$RUN.PRF" "$DEBUG_XML" >"$OUT/$RUN.txt"
echo "wrote $OUT/$RUN.PRF, $OUT/$RUN.txt and $OUT/$RUN-memory.txt"
