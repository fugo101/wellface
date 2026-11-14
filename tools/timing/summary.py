"""Summarizes the timing build's log (source/Timing.mc).

Usage: summary.py <log> [<log> ...]

A log is the timing build's System.println output: on the watch the file
GARMIN/Apps/LOGS/WELLFACE.TXT (copied back with scripts/watch-logs.sh), in
the simulator what monkeydo prints. Lines other than the timing lines are
ignored:
  timing flush <reason> <count>   readings printed (reason: sleep, that is
                                  entering AOD; hide; stop; full)
  timing <kind> <ms>              one reading, in milliseconds
Kinds: update (a high-power update; the first after a start and wakes are
filed under their own kinds), aod (an AOD update), first and firstAod (the
first update after a face start, in high power or AOD), wake (the first
high-power update after AOD), frame (FaceModel.update), aodFrame
(FaceModel.updateAod), static (the static layer paint). An update's time
includes the frame and static readings taken inside it.

Prints, for each log and, with several logs, for all of them pooled: per
kind the count, median, 10th and 90th percentile, minimum, maximum and mean
in ms, then the flushes per reason.
"""

from __future__ import annotations

import statistics
import sys
from collections import Counter, defaultdict
from pathlib import Path

KINDS = ["update", "wake", "first", "firstAod", "aod", "frame", "aodFrame", "static"]


def read(path: Path) -> tuple[dict[str, list[int]], Counter[str]]:
    readings: dict[str, list[int]] = defaultdict(list)
    flushes: Counter[str] = Counter()
    for line in path.read_text(errors="replace").splitlines():
        parts = line.split()
        if len(parts) < 3 or parts[0] != "timing":
            continue
        if parts[1] == "flush":
            flushes[parts[2]] += 1
        elif parts[2].lstrip("-").isdigit():
            readings[parts[1]].append(int(parts[2]))
    return readings, flushes


def percentile(values: list[int], p: float) -> float:
    """Linear interpolation between closest ranks (statistics' 'inclusive')."""
    if len(values) == 1:
        return float(values[0])
    return statistics.quantiles(values, n=100, method="inclusive")[round(p) - 1]


def report(title: str, readings: dict[str, list[int]], flushes: Counter[str]) -> None:
    print(f"== {title}")
    print(f"{'kind':<9} {'n':>5} {'median':>7} {'p10':>6} {'p90':>6} {'min':>5} {'max':>5} {'mean':>7}")
    for kind in KINDS + sorted(set(readings) - set(KINDS)):
        values = readings.get(kind)
        if not values:
            continue
        print(f"{kind:<9} {len(values):>5} {statistics.median(values):>7.1f} "
              f"{percentile(values, 10):>6.1f} {percentile(values, 90):>6.1f} "
              f"{min(values):>5} {max(values):>5} {statistics.fmean(values):>7.1f}")
    print("flushes: " + (", ".join(f"{r} {n}" for r, n in sorted(flushes.items())) or "none"))


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__.strip().splitlines()[2], file=sys.stderr)
        return 2
    pooled: dict[str, list[int]] = defaultdict(list)
    pooled_flushes: Counter[str] = Counter()
    for name in sys.argv[1:]:
        readings, flushes = read(Path(name))
        report(name, readings, flushes)
        for kind, values in readings.items():
            pooled[kind].extend(values)
        pooled_flushes.update(flushes)
    if len(sys.argv) > 2:
        report("pooled", pooled, pooled_flushes)
    return 0


if __name__ == "__main__":
    sys.exit(main())
