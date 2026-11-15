#!/usr/bin/env bash
# Regenerates the contour texture's pieces (tools/contourgen/generate.py):
# resources/contours/contours.json and contours.xml, from the design's
# contour lines and the field geometry in source/Layout.mc. Run it after any
# change to the wells, rims or the background disc; tests/ContourTest.mc
# fails until it is run. Standard library only, no network.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PYTHON="${PYTHON:-python3.15}"
command -v "$PYTHON" >/dev/null || { echo "error: $PYTHON not found (set PYTHON=...)" >&2; exit 2; }

"$PYTHON" -I "$ROOT/tools/contourgen/generate.py"
