"""Compares simulator captures pixel by pixel (scripts/capture.sh --compare).

Usage: compare.py <before dir> <after dir> <scenario>...
Prints the number of differing pixels per scenario, ignoring the window's
title bar and status bar (the status bar shows the app's memory use). Exits 1
if any capture differs or is missing, else 0.
"""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageChops

# Rows ignored at the top (title bar) and bottom (status bar), as a fraction
# of the capture's height, so they hold at any display scale.
TOP = 0.035
BOTTOM = 0.035


def differing_pixels(before: Path, after: Path) -> int:
    a = Image.open(before).convert("RGB")
    b = Image.open(after).convert("RGB")
    if a.size != b.size:
        return a.width * a.height
    top, bottom = int(a.height * TOP), int(a.height * (1 - BOTTOM))
    box = (0, top, a.width, bottom)
    # The largest difference of the three channels: a grayscale conversion
    # would hide a small difference in blue (weighted 0.114) or red.
    red, green, blue = ImageChops.difference(a.crop(box), b.crop(box)).split()
    diff = ImageChops.lighter(ImageChops.lighter(red, green), blue)
    return sum(diff.histogram()[1:])  # every pixel whose difference is not 0


def main() -> int:
    before, after, scenarios = Path(sys.argv[1]), Path(sys.argv[2]), sys.argv[3:]
    status = 0
    for scenario in scenarios:
        a, b = before / f"{scenario}.png", after / f"{scenario}.png"
        if not a.exists() or not b.exists():
            print(f"{scenario}: missing capture")
            status = 1
            continue
        count = differing_pixels(a, b)
        print(f"{scenario}: {'identical' if count == 0 else f'{count} pixels differ'}")
        if count:
            status = 1
    return status


if __name__ == "__main__":
    sys.exit(main())
