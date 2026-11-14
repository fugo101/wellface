"""Reads a Connect IQ profiler log (.PRF) without the simulator's profiler window.

Usage: prf.py <file.PRF> <app.prg.debug.xml> [function ...]

A .PRF is a stream of length-prefixed protobuf records (read from the
simulator's own logs, SDK 9.3.0; the format is not documented):
  field 1  time in microseconds since the profiler started
  field 2  on entering, the function's start pc (app code from 0x10000000,
           API code from 0x30000000) or an API method's symbol (from
           0x40000000); 0 on leaving
  field 3  2 = enter Monkey C code, 1 = enter an API method, 3 = leave
  field 4  the caller's pc (not used here)
The first record is a header (field 3 = ticks per second, 1,000,000).

Prints, per function, the call count and the Total, Actual (without the
functions it calls) and Average time in microseconds, like the profiler
window, for the functions named on the command line (every app function if
none). WellfaceView.onUpdate is also split by mode: an update that called
Renderer.paintAod is an Always On update, one that called Renderer.paint a
high-power update.
"""

from __future__ import annotations

import sys
import xml.etree.ElementTree as ET
from collections import defaultdict
from pathlib import Path

ENTERS, LEAVE = (1, 2), 3


def varint(data: bytes, i: int) -> tuple[int, int]:
    value = shift = 0
    while True:
        b = data[i]
        i += 1
        value |= (b & 0x7F) << shift
        if b < 0x80:
            return value, i
        shift += 7


def records(data: bytes):
    i = 0
    while i < len(data):
        length, i = varint(data, i)
        end = i + length
        fields = {}
        while i < end:
            key, i = varint(data, i)
            if key & 7 != 0:
                raise SystemExit(f"unexpected wire type {key & 7} at byte {i}")
            fields[key >> 3], i = varint(data, i)
        yield fields


def function_names(debug_xml: Path) -> dict[int, str]:
    names = {}
    for entry in ET.parse(debug_xml).getroot().iter("functionEntry"):
        start = entry.get("startPc")
        if start is not None:
            fn = entry.get("name") or "?"
            # Private functions come as "<globals/Renderer/<>paintStatic>".
            if fn.startswith("<globals/") and "<>" in fn:
                fn = fn.rsplit("<>", 1)[1].rstrip(">")
            names[int(start)] = f"{entry.get('parent')}.{fn}"
    return names


class Call:
    __slots__ = ("pc", "start", "child_time", "children")

    def __init__(self, pc: int, start: int):
        self.pc, self.start, self.child_time, self.children = pc, start, 0, set()


def main() -> int:
    prf, debug_xml, wanted = Path(sys.argv[1]), Path(sys.argv[2]), sys.argv[3:]
    names = function_names(debug_xml)
    name = lambda pc: names.get(pc, f"<API> ({pc:x})" if pc >= 0x30000000 else f"pc {pc:x}")

    stats = defaultdict(lambda: [0, 0, 0])  # name -> [calls, total, actual]
    modes = defaultdict(lambda: [0, 0])     # mode -> [calls, total]
    stack: list[Call] = []
    first = last = None
    it = records(prf.read_bytes())
    next(it)  # header
    for r in it:
        time, kind = r.get(1, 0), r.get(3)
        first = time if first is None else first
        last = time
        if kind in ENTERS:
            if stack:
                stack[-1].children.add(r.get(2, 0))
            stack.append(Call(r.get(2, 0), time))
        elif kind == LEAVE and stack:
            call = stack.pop()
            elapsed = time - call.start
            fn = name(call.pc)
            s = stats[fn]
            s[0] += 1
            s[1] += elapsed
            s[2] += elapsed - call.child_time
            if stack:
                stack[-1].child_time += elapsed
                stack[-1].children |= call.children
            if fn == "WellfaceView.onUpdate":
                called = {name(pc) for pc in call.children}
                mode = ("Always On" if "Renderer.paintAod" in called
                        else "high power" if "Renderer.paint" in called else "neither")
                modes[mode][0] += 1
                modes[mode][1] += elapsed

    print(f"profiled {((last or 0) - (first or 0)) / 1e6:.1f} s")
    print(f"{'Function':<44}{'Calls':>8}{'Total us':>12}{'Actual us':>12}{'Average us':>12}")
    rows = sorted(stats.items(), key=lambda kv: -kv[1][1])
    for fn, (calls, total, actual) in rows:
        if wanted and fn not in wanted:
            continue
        if not wanted and fn.startswith("<API"):
            continue
        print(f"{fn:<44}{calls:>8}{total:>12}{actual:>12}{total / calls:>12.1f}")
    for mode, (calls, total) in sorted(modes.items()):
        print(f"WellfaceView.onUpdate, {mode:<22}{calls:>8}{total:>12}{'':>12}{total / calls:>12.1f}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
