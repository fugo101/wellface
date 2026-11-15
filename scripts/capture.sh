#!/usr/bin/env bash
# Screenshots of the face in the simulator for fixed scenarios, to compare a
# change against captures taken before it. Builds the capture face
# (tools/capture) once per scenario, loads it into the simulator and captures
# the simulator window. macOS only: it uses osascript and screencapture, so the
# terminal needs the Screen Recording permission.
#
# Usage: scripts/capture.sh <out dir> [--compare <dir>]
#   Writes <out dir>/<scenario>.png for every scenario. With --compare, also
#   compares each capture with <dir>/<scenario>.png and reports the number of
#   differing pixels (title bar and status bar excluded).
#   The face is captured in the mint theme, whatever theme the built-in face
#   config names, so captures stay comparable; CAPTURE_THEME=<theme name>
#   (for example volt) captures another theme.
#
# Exit codes: 0 captured (and, with --compare, every capture identical),
# 1 a capture differs, 2 could not run.
JUNGLE="$(cd "$(dirname "$0")/.." && pwd)/tools/capture/monkey.jungle"
source "$(dirname "$0")/common.sh"

SCENARIOS=(frame1 frame1sec00 frame2 frame3 frame5 frame7 frame11 frame11b frame12 goalReached warning longSteps steps100000)
SCENARIO_DIR="$ROOT/tools/capture/scenario"
PRG="$BIN/capture.prg"
PYTHON="$ROOT/.venv/bin/python"

[[ $# -eq 1 || ( $# -eq 3 && "$2" == "--compare" ) ]] \
    || die "usage: scripts/capture.sh <out dir> [--compare <dir>]"
OUT="$1"
BEFORE="${3:-}"
[[ "$(uname)" == "Darwin" ]] || die "capturing needs macOS (osascript, screencapture)"
if [[ -n "$BEFORE" ]]; then
    [[ -d "$BEFORE" ]] || die "$BEFORE is not a folder"
    [[ -x "$PYTHON" ]] || die "no .venv with Pillow; run scripts/gen-fonts.sh once to create it"
fi
# An unknown name would silently capture mint (the fallback theme), so check
# it against the theme names in source/Theme.mc.
THEME="${CAPTURE_THEME:-mint}"
grep -q "^    const [A-Z]* = \"$THEME\";" "$ROOT/source/Theme.mc" \
    || die "unknown theme \"$THEME\" in CAPTURE_THEME (theme names are lowercase, as in source/Theme.mc)"
# CAPTURE_FULL_REPAINT=1 forces the renderer's full repaint (its fallback
# when the graphics pool has no room) instead of the per-second path.
FULL_REPAINT=false
[[ "${CAPTURE_FULL_REPAINT:-}" == "1" ]] && FULL_REPAINT=true
mkdir -p "$OUT" "$SCENARIO_DIR"

"$CIQ_SDK/bin/connectiq"   # starts the simulator, or focuses it if running

# The CGWindowID of the simulator's device window, so it is captured even
# when another window covers it.
window_id() {
    osascript -l JavaScript -e '
        ObjC.import("CoreGraphics");
        const list = ObjC.castRefToObject($.CGWindowListCopyWindowInfo(0, 0));
        let id = "";
        for (let i = 0; i < list.count; i++) {
            const w = list.objectAtIndex(i);
            const name = ObjC.unwrap(w.objectForKey("kCGWindowName"));
            if (typeof name === "string" && name.startsWith("CIQ Simulator")) {
                id = String(ObjC.unwrap(w.objectForKey("kCGWindowNumber")));
            }
        }
        id;'
}

for scenario in "${SCENARIOS[@]}"; do
    printf 'module CaptureScenario {\n    const NAME = "%s";\n    const THEME = "%s";\n    const FULL_REPAINT = %s;\n}\n' \
        "$scenario" "$THEME" "$FULL_REPAINT" >"$SCENARIO_DIR/Scenario.mc"
    compile "$PRG" >/dev/null
    log="$(mktemp)"
    loaded=0
    for _ in $(seq 1 30); do
        "$CIQ_SDK/bin/monkeydo" "$PRG" "$DEVICE" >"$log" 2>&1 &
        pid=$!
        sleep 5   # loading and the first update
        if ! grep -q "Unable to connect to simulator" "$log"; then
            loaded=1
            break
        fi
        wait "$pid" 2>/dev/null || true
    done
    [[ $loaded -eq 1 ]] || die "could not reach the simulator"
    id="$(window_id)"
    [[ -n "$id" ]] || die "no simulator window found (Screen Recording permission?)"
    screencapture -x -o -l"$id" "$OUT/$scenario.png" \
        || die "screencapture failed (Screen Recording permission?)"
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
    rm -f "$log"
    echo "captured $OUT/$scenario.png"
done

[[ -n "$BEFORE" ]] || exit 0
"$PYTHON" -I "$ROOT/tools/capture/compare.py" "$BEFORE" "$OUT" "${SCENARIOS[@]}"
