"""Summarizes the timing build's log (source/Timing.mc).

Usage: summary.py <log> [<log> ...]

A log is the timing build's System.println output: on the watch the file
GARMIN/Apps/LOGS/WELLFACE.TXT (copied back with scripts/watch-logs.sh; once
it passes about 5 kB the watch moves it to WELLFACE.BAK and starts a new
one, so join WELLFACE.BAK and WELLFACE.TXT, in that order, into one log), in
the simulator what monkeydo prints. Lines other than the timing lines are
ignored:
  timing flush <reason> <count>   a flush of <count> readings (reason:
                                  sleep, that is entering AOD; hide; stop;
                                  full)
  timing u19 f4 u23 ...           readings: a kind's code, then milliseconds
The first logs (ticket 01's wears 1 and 2) have one "timing <kind> <ms>"
line per reading; they are read too.

Kinds (code): update (u, a high-power update; those below are filed under
their own kinds), first (F) and firstAod (A, the first update after a face
start, in high power or AOD), show (h, the first high-power update after the
view was hidden and shown again without a restart), wake (w, the first
high-power update after AOD), aod (a, an AOD update), frame (f,
FaceModel.update), aodFrame (d, FaceModel.updateAod), static (s, the static
layer paint). An update's time includes the frame and static readings taken
inside it. Before the show kind existed, a show was filed as first.

Prints, for each log and, with several logs, for all of them pooled: per
kind the count, median, 10th and 90th percentile, minimum, maximum and mean
in ms, the high-power updates also split by whether the frame was
recomputed in them (update+frame, update-frame); the flushes per reason; and a warning when readings are missing (a
flush with fewer readings than its header says, or readings before the first
header: the start of the log was moved away, see WELLFACE.BAK).
"""

from __future__ import annotations

import re
import statistics
import sys
from collections import Counter, defaultdict
from dataclasses import dataclass, field
from pathlib import Path

CODES = {"u": "update", "a": "aod", "F": "first", "A": "firstAod", "w": "wake",
         "h": "show", "f": "frame", "d": "aodFrame", "s": "static"}
KINDS = ["update", "wake", "show", "first", "firstAod", "aod", "frame", "aodFrame", "static"]
# High-power updates split by whether the frame was recomputed in them (a
# frame reading comes just before its update's reading). The two groups sit
# about 4 ms apart on the watch, so the plain update median jumps between
# them with the mix; compare each group's median, or the mean.
SPLIT = ["update+frame", "update-frame"]
READING = re.compile(r"^([A-Za-z])(\d+)$")


@dataclass
class Log:
    readings: dict[str, list[int]] = field(default_factory=lambda: defaultdict(list))
    flushes: Counter[str] = field(default_factory=Counter)
    # Readings before the first header, and readings a header announced
    # that never came.
    orphans: int = 0
    missing: int = 0

    def add(self, other: Log) -> None:
        for kind, values in other.readings.items():
            self.readings[kind].extend(values)
        self.flushes.update(other.flushes)
        self.orphans += other.orphans
        self.missing += other.missing


def read(path: Path) -> Log:
    log = Log()
    expected: int | None = None   # readings still due in the current flush

    last = ""

    def reading(kind: str, ms: int) -> None:
        nonlocal expected, last
        log.readings[kind].append(ms)
        if kind == "update":
            log.readings[SPLIT[0] if last == "frame" else SPLIT[1]].append(ms)
        last = kind
        if expected is None:
            log.orphans += 1
        else:
            expected -= 1

    for line in path.read_text(errors="replace").splitlines():
        parts = line.split()
        if len(parts) < 2 or parts[0] != "timing":
            continue
        if parts[1] == "flush" and len(parts) == 4:
            if expected:
                log.missing += max(0, expected)
            expected = int(parts[3])
            log.flushes[parts[2]] += 1
            last = ""
        elif len(parts) == 3 and parts[1] in KINDS and parts[2].isdigit():
            reading(parts[1], int(parts[2]))
        else:
            for token in parts[1:]:
                match = READING.match(token)
                if match and match.group(1) in CODES:
                    reading(CODES[match.group(1)], int(match.group(2)))
    if expected:
        log.missing += max(0, expected)
    return log


def percentile(values: list[int], p: float) -> float:
    """Linear interpolation between closest ranks (statistics' 'inclusive')."""
    if len(values) == 1:
        return float(values[0])
    return statistics.quantiles(values, n=100, method="inclusive")[round(p) - 1]


def report(title: str, log: Log) -> None:
    print(f"== {title}")
    print(f"{'kind':<12} {'n':>5} {'median':>7} {'p10':>6} {'p90':>6} {'min':>5} {'max':>5} {'mean':>7}")
    for kind in KINDS[:1] + SPLIT + KINDS[1:]:
        values = log.readings.get(kind)
        if not values:
            continue
        print(f"{kind:<12} {len(values):>5} {statistics.median(values):>7.1f} "
              f"{percentile(values, 10):>6.1f} {percentile(values, 90):>6.1f} "
              f"{min(values):>5} {max(values):>5} {statistics.fmean(values):>7.1f}")
    print("flushes: " + (", ".join(f"{r} {n}" for r, n in sorted(log.flushes.items())) or "none"))
    if log.orphans or log.missing:
        print(f"warning: {log.orphans} readings before the first flush header, "
              f"{log.missing} announced readings missing; part of the log was lost "
              "(join WELLFACE.BAK before WELLFACE.TXT)")


def main() -> int:
    if len(sys.argv) < 2:
        print("usage: summary.py <log> [<log> ...]", file=sys.stderr)
        return 2
    pooled = Log()
    for name in sys.argv[1:]:
        log = read(Path(name))
        report(name, log)
        pooled.add(log)
    if len(sys.argv) > 2:
        report("pooled", pooled)
    return 0


if __name__ == "__main__":
    sys.exit(main())
