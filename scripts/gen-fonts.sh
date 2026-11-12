#!/usr/bin/env bash
# Regenerates the bitmap fonts and glyph-width tables (tools/fontgen/generate.py).
# Downloads the source fonts fresh from Google Fonts, so it needs the network.
# Creates the gitignored .venv on first run and keeps it on the pinned requirements.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PYTHON="${PYTHON:-python3.15}"
VENV="$ROOT/.venv"
REQS="$ROOT/tools/fontgen/requirements.txt"

if [[ ! -x "$VENV/bin/python" ]]; then
    command -v "$PYTHON" >/dev/null || { echo "error: $PYTHON not found (set PYTHON=...)" >&2; exit 2; }
    "$PYTHON" -m venv "$VENV"
    "$VENV/bin/python" -m pip install --quiet --upgrade pip
fi
# Every run, so the venv follows the pins in requirements.txt.
"$VENV/bin/python" -m pip install --quiet -r "$REQS"

"$VENV/bin/python" -I "$ROOT/tools/fontgen/generate.py"
