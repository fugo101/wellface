"""Contour texture generator for Wellface (Q43).

Computes the final design's contour lines (its `topo` function: closed wavy
lines around a peak in the lower left), cuts them in advance into contour
pieces that lie between the wells, and writes them as packed numbers:

- resources/contours/contours.json: the pieces, drawn with drawLine;
- resources/contours/contours.xml: its jsonData resource.

Filled strips (fillPolygon) were tried as well in ticket 09 and dropped:
about six times slower than lines on the FR265.

The field geometry is read from source/Layout.mc, so the face and the table
share one source. tests/ContourTest.mc checks the table against the layout
again on the watch side, so a layout change without running this script
fails a test.

Run it with scripts/gen-contours.sh. Standard library only.
"""

from __future__ import annotations

import json
import math
import re
import sys
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LAYOUT_FILE = ROOT / "source" / "Layout.mc"
OUT_DIR = ROOT / "resources" / "contours"

# The design's contour lines (`TOPO` and `topo` in buildG's file): line l of
# LINES has POINTS points, point j at t = 2 pi j / POINTS, radius
# SPACING * l * f(t) around (PEAK_X, PEAK_Y), joined into a closed polyline.
PEAK_X = 132
PEAK_Y = 318
SPACING = 13
LINES = 40
POINTS = 64
# Pen 2, every 5th line pen 3.
PEN = 2
MAJOR_PEN = 3
MAJOR_EVERY = 5

# A cut piece keeps its center line this much further from every limit than
# the margins require, so rounding its points to whole pixels (at most
# sqrt(1/2) px away) never breaks them.
ROUNDING_SAFETY = 0.75
# Pieces shorter than this (px, along the line) are dropped.
MIN_PIECE_LENGTH = 3.0
# Sampling step (px) along a segment when looking for the cuts, before each
# cut is refined by bisection.
SAMPLE_STEP = 0.05

# Packing (source/Contours.mc reads it): a piece starts with a header,
# -(line << 16 | pen << 8 | count), followed by `count` points, each
# x << 9 | y in whole pixels. Headers are negative and points are not.
LINE_SHIFT = 16
PEN_SHIFT = 8
POINT_SHIFT = 9


def f(t: float) -> float:
    """The design's wave: f = 1 + 0.16 sin(3t + 0.6) + 0.08 sin(5t + 1.9) + 0.05 sin(7t + 0.3)."""
    return 1 + 0.16 * math.sin(3 * t + 0.6) + 0.08 * math.sin(5 * t + 1.9) \
        + 0.05 * math.sin(7 * t + 0.3)


def line_points(l: int) -> list[tuple[float, float]]:
    pts = []
    for j in range(POINTS):
        t = j / POINTS * 2 * math.pi
        r = SPACING * l * f(t)
        pts.append((PEAK_X + r * math.cos(t), PEAK_Y + r * math.sin(t)))
    return pts


def pen_of(l: int) -> int:
    return MAJOR_PEN if l % MAJOR_EVERY == 0 else PEN


# --- Layout -------------------------------------------------------------------

def read_layout() -> dict[str, int]:
    """Every integer constant of the Layout module (const NAME = 123;)."""
    text = LAYOUT_FILE.read_text()
    values = {name: int(value)
              for name, value in re.findall(r"^\s*const ([A-Z0-9_]+) = (-?\d+);", text, re.M)}
    if not values:
        raise SystemExit(f"no constants found in {LAYOUT_FILE}")
    return values


@dataclass
class Circle:
    x: float
    y: float
    r: float


@dataclass
class RoundedRect:
    x: float
    y: float
    w: float
    h: float
    r: float


@dataclass
class ArcBand:
    """The points within `half_pen` of an arc of radius `r` around (x, y),
    from -half_angle to +half_angle design degrees (0 = 12 o'clock): a
    flat-ended arc with a round cap at each end."""
    x: float
    y: float
    r: float
    half_angle: float
    half_pen: float


@dataclass
class Geometry:
    cx: float
    cy: float
    disc: float
    wells: list


def geometry(c: dict[str, int]) -> Geometry:
    """The background disc and the shapes the texture must stay clear of:
    the rimmed wells measured at their rims, and the battery well (no rim)."""
    rim = c["WELL"] + c["WELL_RIM"]
    band = RoundedRect(c["BAND_X"] - rim, c["BAND_Y"] - rim, c["BAND_W"] + 2 * rim,
                       c["BAND_H"] + 2 * rim, c["BAND_RADIUS"] + rim)
    fields = [Circle(c[f"{n}_FIELD_X"], c[f"{n}_FIELD_Y"], c[f"{n}_FIELD_RADIUS"] + rim)
              for n in ("LEFT", "CENTER", "RIGHT")]
    # The bottom field's pill is its own well; its rim is just outside it.
    bottom = RoundedRect(c["BOTTOM_X"] - c["WELL_RIM"], c["BOTTOM_Y"] - c["WELL_RIM"],
                         c["BOTTOM_W"] + 2 * c["WELL_RIM"], c["BOTTOM_H"] + 2 * c["WELL_RIM"],
                         c["BOTTOM_RADIUS"] + c["WELL_RIM"])
    battery = ArcBand(c["CENTER_X"], c["CENTER_Y"], c["BATTERY_RADIUS"],
                      c["BATTERY_WELL_HALF"], c["BATTERY_WELL_PEN"] / 2)
    return Geometry(c["CENTER_X"], c["CENTER_Y"], c["DISC_RADIUS"],
                    [band, *fields, bottom, battery])


# --- Distances ----------------------------------------------------------------

def point_distance(px: float, py: float, shape) -> float:
    """Distance from a point to a shape (0 inside it)."""
    if isinstance(shape, Circle):
        return max(0.0, math.hypot(px - shape.x, py - shape.y) - shape.r)
    if isinstance(shape, RoundedRect):
        # Distance to the inner rect, less the corner radius.
        x0, y0 = shape.x + shape.r, shape.y + shape.r
        x1, y1 = shape.x + shape.w - shape.r, shape.y + shape.h - shape.r
        dx = max(x0 - px, 0.0, px - x1)
        dy = max(y0 - py, 0.0, py - y1)
        return max(0.0, math.hypot(dx, dy) - shape.r)
    if isinstance(shape, ArcBand):
        dx, dy = px - shape.x, py - shape.y
        angle = math.degrees(math.atan2(dx, -dy))
        if abs(angle) <= shape.half_angle:
            d = abs(math.hypot(dx, dy) - shape.r)
        else:
            d = min(math.hypot(px - ex, py - ey) for ex, ey in arc_ends(shape))
        return max(0.0, d - shape.half_pen)
    raise TypeError(shape)


def arc_ends(shape: ArcBand) -> list[tuple[float, float]]:
    a = math.radians(shape.half_angle)
    return [(shape.x + s * shape.r * math.sin(a), shape.y - shape.r * math.cos(a)) for s in (-1, 1)]


def segment_point_distance(ax, ay, bx, by, px, py) -> float:
    vx, vy = bx - ax, by - ay
    length2 = vx * vx + vy * vy
    t = 0.0 if length2 == 0 else max(0.0, min(1.0, ((px - ax) * vx + (py - ay) * vy) / length2))
    return math.hypot(ax + t * vx - px, ay + t * vy - py)


def segments_intersect(a, b, c, d) -> bool:
    def cross(o, p, q):
        return (p[0] - o[0]) * (q[1] - o[1]) - (p[1] - o[1]) * (q[0] - o[0])
    d1, d2 = cross(c, d, a), cross(c, d, b)
    d3, d4 = cross(a, b, c), cross(a, b, d)
    return ((d1 > 0) != (d2 > 0)) and ((d3 > 0) != (d4 > 0))


def segment_distance(a, b, shape) -> float:
    """Exact distance from segment a-b to a shape (0 if they touch). The same
    computation as tests/ContourTest.mc."""
    ax, ay = a
    bx, by = b
    if isinstance(shape, Circle):
        return max(0.0, segment_point_distance(ax, ay, bx, by, shape.x, shape.y) - shape.r)
    if isinstance(shape, RoundedRect):
        # Segment to the inner rect (convex): 0 if an end is inside or the
        # segment crosses an edge, else the least of the ends' distances to
        # the rect and the corners' distances to the segment.
        x0, y0 = shape.x + shape.r, shape.y + shape.r
        x1, y1 = shape.x + shape.w - shape.r, shape.y + shape.h - shape.r
        corners = [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]

        def to_rect(px, py):
            return math.hypot(max(x0 - px, 0.0, px - x1), max(y0 - py, 0.0, py - y1))
        d = min(to_rect(ax, ay), to_rect(bx, by))
        if d > 0:
            for i in range(4):
                if segments_intersect(a, b, corners[i], corners[(i + 1) % 4]):
                    d = 0.0
                    break
        if d > 0:
            d = min([d] + [segment_point_distance(ax, ay, bx, by, cx, cy) for cx, cy in corners])
        return max(0.0, d - shape.r)
    if isinstance(shape, ArcBand):
        # The arc's ends (the caps' centers), then the part of the segment
        # inside the arc's wedge, where the distance is | |p| - r |.
        d = min(segment_point_distance(ax, ay, bx, by, ex, ey) for ex, ey in arc_ends(shape))
        clipped = clip_to_wedge(a, b, shape)
        if clipped is not None:
            (px, py), (qx, qy) = clipped
            near = segment_point_distance(px, py, qx, qy, shape.x, shape.y)
            far = max(math.hypot(px - shape.x, py - shape.y), math.hypot(qx - shape.x, qy - shape.y))
            if near <= shape.r <= far:
                d = 0.0
            elif far < shape.r:
                d = min(d, shape.r - far)
            else:
                d = min(d, near - shape.r)
        return max(0.0, d - shape.half_pen)
    raise TypeError(shape)


def clip_to_wedge(a, b, shape: ArcBand):
    """The part of segment a-b inside the arc's wedge (its center and the
    angles from -half_angle to +half_angle), or None."""
    h = math.radians(shape.half_angle)
    # Inward normals of the wedge's two edges (screen y grows down, the
    # wedge opens upward): points p with n . (p - c) >= 0 are inside.
    normals = [(-math.cos(h), -math.sin(h)), (math.cos(h), -math.sin(h))]
    t0, t1 = 0.0, 1.0
    for nx, ny in normals:
        fa = nx * (a[0] - shape.x) + ny * (a[1] - shape.y)
        fb = nx * (b[0] - shape.x) + ny * (b[1] - shape.y)
        if fa < 0 and fb < 0:
            return None
        if fa < 0 or fb < 0:
            t = fa / (fa - fb)
            if fa < 0:
                t0 = max(t0, t)
            else:
                t1 = min(t1, t)
    if t0 > t1:
        return None

    def at(t):
        return (a[0] + t * (b[0] - a[0]), a[1] + t * (b[1] - a[1]))
    return at(t0), at(t1)


# --- Cutting ------------------------------------------------------------------

def point_ok(p, pen: int, g: Geometry, safety: float) -> bool:
    if math.hypot(p[0] - g.cx, p[1] - g.cy) > g.disc - pen / 2 - safety:
        return False
    return all(point_distance(p[0], p[1], w) >= pen + safety for w in g.wells)


def segment_ok(a, b, pen: int, g: Geometry) -> bool:
    """Whether segment a-b keeps the margins: at least half a pen inside the
    disc and at least a pen outside every well."""
    limit = g.disc - pen / 2
    if math.hypot(a[0] - g.cx, a[1] - g.cy) > limit or math.hypot(b[0] - g.cx, b[1] - g.cy) > limit:
        return False
    return all(segment_distance(a, b, w) >= pen for w in g.wells)


def good_runs(a, b, pen: int, g: Geometry) -> list[tuple[float, float]]:
    """The parameter intervals of segment a-b whose points keep the margins
    plus the rounding safety."""
    length = math.hypot(b[0] - a[0], b[1] - a[1])
    steps = max(1, math.ceil(length / SAMPLE_STEP))

    def ok(t):
        return point_ok((a[0] + t * (b[0] - a[0]), a[1] + t * (b[1] - a[1])), pen, g,
                        ROUNDING_SAFETY)

    def edge(lo, hi):
        # ok(lo) != ok(hi); the parameter where it changes.
        want = ok(lo)
        for _ in range(40):
            mid = (lo + hi) / 2
            if ok(mid) == want:
                lo = mid
            else:
                hi = mid
        return lo if want else hi

    runs = []
    start = 0.0 if ok(0.0) else None
    prev_t, prev_ok = 0.0, start is not None
    for i in range(1, steps + 1):
        t = i / steps
        now = ok(t)
        if now and not prev_ok:
            start = edge(prev_t, t)
        elif prev_ok and not now:
            runs.append((start, edge(prev_t, t)))
            start = None
        prev_t, prev_ok = t, now
    if prev_ok:
        runs.append((start, 1.0))
    return runs


def cut_line(l: int, g: Geometry) -> list[list[tuple[float, float]]]:
    """Line l cut into pieces (polylines with exact points)."""
    pts = line_points(l)
    pen = pen_of(l)
    pieces: list[list[tuple[float, float]]] = []
    current: list[tuple[float, float]] | None = None
    for j in range(POINTS):
        a, b = pts[j], pts[(j + 1) % POINTS]

        def at(t):
            # Exactly the line's own points at the ends.
            if t == 0.0:
                return a
            if t == 1.0:
                return b
            return (a[0] + t * (b[0] - a[0]), a[1] + t * (b[1] - a[1]))
        for t0, t1 in good_runs(a, b, pen, g):
            if current is not None and t0 == 0.0:
                current.append(at(t1))
            else:
                if current is not None:
                    pieces.append(current)
                current = [at(t0), at(t1)]
            if t1 < 1.0:
                pieces.append(current)
                current = None
    if current is not None:
        pieces.append(current)
    # The line is closed: a piece reaching the last point continues into one
    # starting at the first.
    if len(pieces) > 1 and pieces[-1][-1] == pts[0] and pieces[0][0] == pts[0]:
        pieces[0] = pieces.pop()[:-1] + pieces[0]
    return pieces


def length_of(piece) -> float:
    return sum(math.hypot(q[0] - p[0], q[1] - p[1]) for p, q in zip(piece, piece[1:]))


def rounded(piece) -> list[tuple[int, int]]:
    out: list[tuple[int, int]] = []
    for x, y in piece:
        p = (math.floor(x + 0.5), math.floor(y + 0.5))
        if not out or out[-1] != p:
            out.append(p)
    return out


# --- Output -------------------------------------------------------------------

def header(l: int, pen: int, count: int) -> int:
    return -((l << LINE_SHIFT) | (pen << PEN_SHIFT) | count)


def main() -> None:
    g = geometry(read_layout())
    # Keep the lines that reach the background disc: their nearest point to
    # the disc's center is inside it.
    kept = []
    for l in range(1, LINES + 1):
        nearest = min(math.hypot(x - g.cx, y - g.cy) for x, y in line_points(l))
        if nearest < g.disc:
            kept.append(l)
    if kept != list(range(1, kept[-1] + 1)):
        raise SystemExit(f"the lines reaching the disc are not 1..n: {kept}")

    table: list[int] = []
    segments = 0
    pieces_out = 0
    for l in kept:
        pen = pen_of(l)
        for piece in cut_line(l, g):
            if length_of(piece) < MIN_PIECE_LENGTH:
                continue
            pts = rounded(piece)
            if len(pts) < 2:
                continue
            for a, b in zip(pts, pts[1:]):
                if not segment_ok(a, b, pen, g):
                    raise SystemExit(f"line {l}: segment {a}-{b} breaks a margin after rounding")
            table.append(header(l, pen, len(pts)))
            table += [(x << POINT_SHIFT) | y for x, y in pts]
            segments += len(pts) - 1
            pieces_out += 1

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    (OUT_DIR / "contours.json").write_text(json.dumps(table, separators=(",", ":")) + "\n")
    (OUT_DIR / "contours.xml").write_text(
        "<!-- Generated by tools/contourgen/generate.py. Do not edit. -->\n"
        "<resources>\n"
        "    <jsonData id=\"Contours\" filename=\"contours.json\"/>\n"
        "</resources>\n")
    print(f"lines 1-{kept[-1]} reach the disc (r {g.disc:g}); "
          f"{pieces_out} pieces, {segments} segments, {len(table)} numbers")


if __name__ == "__main__":
    sys.exit(main())
