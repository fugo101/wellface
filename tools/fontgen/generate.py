"""Font generator for Wellface.

Downloads the source fonts fresh from Google Fonts (the google/fonts
repository), renders the bitmap fonts the face uses and writes:

- resources/fonts/<name>.fnt + <name>.png: text BMFont, one 8-bit grayscale
  page per font, white on black (the compiler reads coverage as brightness);
- resources/fonts/fonts.xml: the font resources, antialiased, with a filter;
- resources/fonts/OFL-<family>.txt: the license of every source font used;
- source/FontCatalog.mc: the font catalog, one entry per font (the icon font
  included) holding its resource, glyph set, exactly the xadvance values
  written to its .fnt, base, cap height and letter spacing, plus the code
  point of every icon. FaceModel measures text and the renderer loads and
  draws fonts through the same entry.

Run it with scripts/gen-fonts.sh. To add a font, add an entry to FONTS; to add
an icon, add an entry to ICONS.
"""

from __future__ import annotations

import json
import os
import re
import sys
import tempfile
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass
from pathlib import Path

from fontTools.pens.basePen import BasePen
from fontTools.pens.boundsPen import BoundsPen
from fontTools.svgLib.path import parse_path
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
FONT_DIR = ROOT / "resources" / "fonts"
CATALOG_FILE = ROOT / "source" / "FontCatalog.mc"

REPO_API = "https://api.github.com/repos/google/fonts"
RAW = "https://raw.githubusercontent.com/google/fonts"

# Glyphs are rendered at this multiple of the target size and box-filtered
# down, from the font's unhinted geometry.
SUPERSAMPLE = 4
# Empty pixels kept around each glyph while rendering (1x).
MARGIN = 4
# Width of the texture page and the gap between glyphs on it.
PAGE_WIDTH = 256
SPACING = 1

DIGITS = "0123456789"
LETTERS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"


# --- Sources ------------------------------------------------------------------

@dataclass
class SourceFont:
    """A font file ready to render, and where it came from."""
    path: Path
    face: str          # name written to the .fnt (no spaces: the compiler splits on them)
    license_name: str  # OFL-<license_name>.txt
    license_text: bytes
    origin: str        # one line for the report


class GoogleFonts:
    """Reads google/fonts at one commit, so every file comes from the same tree:
    the latest on main, or GOOGLE_FONTS_COMMIT when set, to rebuild exactly
    the fonts generated from that commit (docs/build.md, "Fonts")."""

    def __init__(self, work: Path):
        self.work = work
        ref = os.environ.get("GOOGLE_FONTS_COMMIT") or "main"
        self.sha = _get(f"{REPO_API}/commits/{urllib.parse.quote(ref)}",
                        accept="application/vnd.github.sha").decode().strip()

    def list(self, folder: str) -> list[str]:
        try:
            items = json.loads(_get(f"{REPO_API}/contents/{folder}?ref={self.sha}"))
        except urllib.error.HTTPError as e:
            if e.code == 404:
                return []
            raise
        return [item["name"] for item in items]

    def fetch(self, folder: str, name: str) -> bytes:
        quoted = urllib.parse.quote(name)
        return _get(f"{RAW}/{self.sha}/{folder}/{quoted}")

    def save(self, folder: str, name: str) -> Path:
        path = self.work / name
        path.write_bytes(self.fetch(folder, name))
        return path


def _get(url: str, accept: str | None = None) -> bytes:
    request = urllib.request.Request(url, headers={"User-Agent": "fontgen"})
    if accept:
        request.add_header("Accept", accept)
    with urllib.request.urlopen(request, timeout=60) as response:
        return response.read()


# Big Shoulders Display is the opsz=72 subspace of the variable "Big Shoulders"
# family (ofl/bigshouldersdisplay/config.yaml in google/fonts).
DISPLAY_OPSZ = 72


def big_shoulders_display_extrabold(gf: GoogleFonts) -> SourceFont:
    """The time font: a static Display ExtraBold if Google Fonts still
    publishes one, otherwise the variable family instanced at wght 800 and
    the Display opsz."""
    display = "ofl/bigshouldersdisplay"
    display_files = gf.list(display)
    static_name = "BigShouldersDisplay-ExtraBold.ttf"
    for folder, files in ((display, display_files),
                          (f"{display}/static", gf.list(f"{display}/static")
                           if "static" in display_files else [])):
        if static_name in files:
            return SourceFont(
                path=gf.save(folder, static_name),
                face="BigShouldersDisplay-ExtraBold",
                license_name="BigShoulders",
                license_text=gf.fetch(display, "OFL.txt"),
                origin=f"static {folder}/{static_name} @ google/fonts {gf.sha[:12]}",
            )

    if "config.yaml" in display_files:
        config = gf.fetch(display, "config.yaml").decode()
        match = re.search(r"axes:\s*opsz=(\d+)", config)
        if not match or int(match.group(1)) != DISPLAY_OPSZ:
            raise SystemExit(f"{display}/config.yaml no longer subspaces opsz={DISPLAY_OPSZ}")
    else:
        print(f"note: {display}/config.yaml not found; opsz {DISPLAY_OPSZ} not re-verified")

    family = "ofl/bigshoulders"
    variable = "BigShoulders[opsz,wght].ttf"
    if variable not in gf.list(family):
        raise SystemExit(f"{family}/{variable} is not published any more")
    source = TTFont(gf.save(family, variable))
    instance = instancer.instantiateVariableFont(source, {"wght": 800, "opsz": DISPLAY_OPSZ})
    path = gf.work / "BigShouldersDisplay-ExtraBold.ttf"
    instance.save(path)
    return SourceFont(
        path=path,
        face="BigShouldersDisplay-ExtraBold",
        license_name="BigShoulders",
        license_text=gf.fetch(family, "OFL.txt"),
        origin=(f"{family}/{variable} instanced at wght 800, opsz {DISPLAY_OPSZ} "
                f"@ google/fonts {gf.sha[:12]} (no static Display ExtraBold published)"),
    )


def manrope(gf: GoogleFonts, weight: int) -> SourceFont:
    """Manrope at one weight: a static file if Google Fonts publishes one,
    otherwise the variable family instanced at that weight."""
    folder = "ofl/manrope"
    names = {700: "Bold", 800: "ExtraBold"}
    face = f"Manrope-{names[weight]}"
    files = gf.list(folder)
    license_text = gf.fetch(folder, "OFL.txt")
    for sub, sub_files in ((folder, files),
                           (f"{folder}/static", gf.list(f"{folder}/static")
                            if "static" in files else [])):
        if f"{face}.ttf" in sub_files:
            return SourceFont(
                path=gf.save(sub, f"{face}.ttf"),
                face=face,
                license_name="Manrope",
                license_text=license_text,
                origin=f"static {sub}/{face}.ttf @ google/fonts {gf.sha[:12]}",
            )

    variable = "Manrope[wght].ttf"
    if variable not in files:
        raise SystemExit(f"{folder}/{variable} is not published any more")
    source = TTFont(gf.save(folder, variable))
    instance = instancer.instantiateVariableFont(source, {"wght": weight})
    path = gf.work / f"{face}.ttf"
    instance.save(path)
    return SourceFont(
        path=path,
        face=face,
        license_name="Manrope",
        license_text=license_text,
        origin=(f"{folder}/{variable} instanced at wght {weight} "
                f"@ google/fonts {gf.sha[:12]} (no static {face} published)"),
    )


SOURCES = {
    "big-shoulders-display-800": big_shoulders_display_extrabold,
    "manrope-800": lambda gf: manrope(gf, 800),
    "manrope-700": lambda gf: manrope(gf, 700),
}


# --- Fonts to generate ----------------------------------------------------------

@dataclass
class FontSpec:
    resource_id: str  # Rez.Fonts.<resource_id>
    file: str         # resources/fonts/<file>.fnt and .png
    font_id: str      # FONT_<font_id>, the font's id in the catalog
    source: str       # key in SOURCES
    size: int         # pixels per em
    glyphs: str
    # Every digit gets this advance (px), its glyph centered in the cell;
    # None keeps the font's own advances.
    tabular_advance: int | None = None
    tracking: int = 0  # px added to every xadvance (baked-in letter spacing)
    digit_height: float | None = None  # asserted height of "0" in px, +-1
    # Asserted xadvances (px) of these glyphs, as the design measures them.
    advances: dict[str, int] | None = None


FONTS = [
    # The time, filled, in both normal mode and Always On (Q12).
    # The source digits are proportional (20.5-38.5 px at 78 px); the design
    # gives every digit a 38 px cell, so "08:42" is 171 px wide.
    FontSpec("Time", "time78", "TIME", "big-shoulders-display-800", 78,
             DIGITS + ":", tabular_advance=38, digit_height=63,
             advances={"0": 38, ":": 19}),
    # The date, for example "THU 12/11" (Q38): letter spacing 2 px.
    FontSpec("Date", "date17", "DATE", "manrope-800", 17,
             LETTERS + DIGITS + "/ ", tracking=2),
    # The center field's number.
    FontSpec("Number48", "number48", "NUMBER_48", "manrope-800", 48, DIGITS + "-"),
    # The left and right numbers by character count (<= 3, 4, >= 5); 22 and
    # 18 also draw the step number, with its thousands dot.
    FontSpec("Number26", "number26", "NUMBER_26", "manrope-800", 26, DIGITS + "-"),
    FontSpec("Number22", "number22", "NUMBER_22", "manrope-800", 22, DIGITS + ".-"),
    FontSpec("Number18", "number18", "NUMBER_18", "manrope-800", 18, DIGITS + ".-"),
    # The bottom field's "/ goal", for example "/ 3.110".
    FontSpec("Goal15", "goal15", "GOAL_15", "manrope-700", 15, DIGITS + "./ "),
]


# --- Icons ----------------------------------------------------------------------

@dataclass
class Icon:
    name: str        # FontCatalog.ICON_<name>, the code point
    code_point: int  # in the Private Use Area
    path: str        # SVG path on the design's 24-unit grid (IC in the design's source)
    # None: filled (nonzero). Otherwise a stroke this wide on the 24-unit
    # grid, with round joins and caps and no fill.
    stroke: float | None = None


# The icon font: every icon is one glyph, ICON_SIZE px square, drawn from its
# box's top-left corner (the glyph keeps its place inside the box).
ICON_FONT_ID = "Icons"  # Rez.Fonts.Icons
ICON_FONT_CATALOG_ID = "ICONS"  # FONT_ICONS
ICON_FONT_FILE = "icons24"
ICON_SIZE = 24
ICONS = [
    Icon("BOLT", 0xE000, "M13.5 2 L5 13.5 H11 L10 22 L19 10 H13 Z"),
    Icon("STRESS", 0xE001, "M2 12 H6 L9 5 L13.5 19 L16.5 9 L18.5 12 H22", stroke=2.5),
    # HEART in the design's source (drawn by its own 'heart' op, not IC).
    Icon("HEART", 0xE002, "M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3"
         "c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5"
         "c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"),
    Icon("FOOT", 0xE003, "M8 2.5c2 0 3.2 2.3 3.2 5.2S10 13 8 13 4.8 10.6 4.8 7.7 6 2.5 8 2.5z "
         "M16 7c2 0 3.2 2.3 3.2 5.2S18 17.5 16 17.5s-3.2-2.4-3.2-5.3S14 7 16 7z "
         "M6 14.5h4v2.5a2 2 0 0 1-4 0z M14 19h4v1a2 2 0 0 1-4 0z"),
]


# --- Rendering ------------------------------------------------------------------

@dataclass
class Glyph:
    char: str
    image: Image.Image  # cropped coverage, L
    xoffset: int
    yoffset: int
    xadvance: int
    x: int = 0
    y: int = 0


@dataclass
class Metrics:
    line_height: int
    base: int
    cap_height: int  # OS/2 sCapHeight, rounded


def render_font(spec: FontSpec, src: SourceFont) -> tuple[list[Glyph], Metrics]:
    tt = TTFont(src.path)
    upm = tt["head"].unitsPerEm
    scale = spec.size / upm
    cmap = tt.getBestCmap()
    glyph_set = tt.getGlyphSet()

    missing = [c for c in spec.glyphs if ord(c) not in cmap]
    if missing:
        raise SystemExit(f"{spec.file}: {src.face} has no glyph for {missing!r}")

    hhea = tt["hhea"]
    base = round(hhea.ascent * scale)
    metrics = Metrics(line_height=round((hhea.ascent - hhea.descent) * scale), base=base,
                      cap_height=round(tt["OS/2"].sCapHeight * scale))

    if spec.digit_height is not None:
        pen = BoundsPen(glyph_set)
        glyph_set[cmap[ord("0")]].draw(pen)
        _, y_min, _, y_max = pen.bounds
        height = (y_max - y_min) * scale
        if abs(height - spec.digit_height) > 1:
            raise SystemExit(f"{spec.file}: '0' is {height:.2f} px tall, "
                             f"expected {spec.digit_height} +-1")

    advances = {c: round(tt["hmtx"][cmap[ord(c)]][0] * scale) for c in spec.glyphs}

    ss = SUPERSAMPLE
    font = ImageFont.truetype(str(src.path), spec.size * ss,
                              layout_engine=ImageFont.Layout.BASIC)
    glyphs = []
    for c in spec.glyphs:
        advance = advances[c]
        width = advance + 2 * MARGIN + spec.size  # room for any overhang
        height = metrics.line_height + 2 * MARGIN + spec.size // 2
        big = Image.new("L", (width * ss, height * ss), 0)
        origin_x, origin_y = MARGIN + spec.size // 2, MARGIN + base
        ImageDraw.Draw(big).text((origin_x * ss, origin_y * ss), c, font=font,
                                 fill=255, anchor="ls")
        image = big.reduce(ss)

        bbox = image.getbbox()
        if bbox is None:
            if not c.isspace():
                raise SystemExit(f"{spec.file}: glyph {c!r} renders empty")
            bbox = (origin_x, origin_y - base, origin_x, origin_y - base)  # 0x0 glyph
        shift = 0
        if spec.tabular_advance is not None and c in DIGITS:
            ink = bbox[2] - bbox[0]
            if ink > spec.tabular_advance:
                raise SystemExit(f"{spec.file}: {c!r} ink is {ink} px, wider than its "
                                 f"{spec.tabular_advance} px cell")
            shift = (spec.tabular_advance - advance) // 2
            advance = spec.tabular_advance
            left = bbox[0] - origin_x + shift
            if left < 0 or left + ink > advance:
                raise SystemExit(f"{spec.file}: {c!r} ink spans {left}..{left + ink} px, "
                                 f"outside its {advance} px cell")
        glyphs.append(Glyph(
            char=c,
            image=image.crop(bbox),
            xoffset=bbox[0] - origin_x + shift,
            yoffset=bbox[1] - (origin_y - base),
            xadvance=advance + spec.tracking,
        ))
    for c, expected in (spec.advances or {}).items():
        actual = next(g.xadvance for g in glyphs if g.char == c)
        if actual != expected:
            raise SystemExit(f"{spec.file}: {c!r} advances {actual} px, expected {expected}")
    return glyphs, metrics


@dataclass
class Contour:
    points: list[tuple[float, float]]
    closed: bool = False


class PolygonPen(BasePen):
    """Collects every contour as a polyline, curves flattened into short lines."""

    CURVE_STEPS = 16

    def __init__(self) -> None:
        super().__init__(None)
        self.contours: list[Contour] = []

    def _moveTo(self, pt):
        self.contours.append(Contour([pt]))

    def _lineTo(self, pt):
        self.contours[-1].points.append(pt)

    def _curveToOne(self, pt1, pt2, pt3):
        points, n = self.contours[-1].points, self.CURVE_STEPS
        x0, y0 = points[-1]
        for i in range(1, n + 1):
            t = i / n
            a, b, c, d = (1 - t) ** 3, 3 * (1 - t) ** 2 * t, 3 * (1 - t) * t * t, t ** 3
            points.append((a * x0 + b * pt1[0] + c * pt2[0] + d * pt3[0],
                           a * y0 + b * pt1[1] + c * pt2[1] + d * pt3[1]))

    def _closePath(self):
        self.contours[-1].closed = True

    def _endPath(self):
        pass


def stroke_polyline(draw: ImageDraw.ImageDraw, points: list[tuple[float, float]],
                    width: float) -> None:
    """A stroke with round joins and caps: a disc on every vertex and a
    rectangle along every segment, which together are exactly the stroke."""
    half = width / 2
    for x, y in points:
        draw.ellipse((x - half, y - half, x + half, y + half), fill=255)
    for (x0, y0), (x1, y1) in zip(points, points[1:]):
        length = ((x1 - x0) ** 2 + (y1 - y0) ** 2) ** 0.5
        if length == 0:
            continue
        nx, ny = -(y1 - y0) / length * half, (x1 - x0) / length * half
        draw.polygon([(x0 + nx, y0 + ny), (x1 + nx, y1 + ny),
                      (x1 - nx, y1 - ny), (x0 - nx, y0 - ny)], fill=255)


def render_icons() -> tuple[list[Glyph], Metrics]:
    """Each icon at ICON_SIZE px, supersampled like the text fonts, either
    filled or stroked. Filled contours are drawn one by one and merged, which
    equals the nonzero rule as long as no contour cuts a hole into another
    (true for every icon)."""
    ss = SUPERSAMPLE
    glyphs = []
    for icon in ICONS:
        if not 0xE000 <= icon.code_point <= 0xF8FF:
            raise SystemExit(f"icon {icon.name}: U+{icon.code_point:04X} is not in the PUA")
        pen = PolygonPen()
        parse_path(icon.path, pen)
        side = ICON_SIZE + 2 * MARGIN
        big = Image.new("L", (side * ss, side * ss), 0)
        draw = ImageDraw.Draw(big)
        for contour in pen.contours:
            points = [((MARGIN + x) * ss, (MARGIN + y) * ss) for x, y in contour.points]
            if icon.stroke is None:
                draw.polygon(points, fill=255)
            else:
                stroke_polyline(draw, points + points[:1] if contour.closed else points,
                                icon.stroke * ss)
        image = big.reduce(ss)
        bbox = image.getbbox()
        if bbox is None:
            raise SystemExit(f"icon {icon.name} renders empty")
        glyphs.append(Glyph(
            char=chr(icon.code_point),
            image=image.crop(bbox),
            xoffset=bbox[0] - MARGIN,
            yoffset=bbox[1] - MARGIN,
            xadvance=ICON_SIZE,
        ))
    return glyphs, Metrics(line_height=ICON_SIZE, base=ICON_SIZE, cap_height=ICON_SIZE)


def pack(glyphs: list[Glyph]) -> Image.Image:
    """Row packing onto one page, SPACING px between glyphs."""
    x = y = row_height = 0
    for g in glyphs:
        if x + g.image.width > PAGE_WIDTH:
            x, y, row_height = 0, y + row_height + SPACING, 0
        g.x, g.y = x, y
        x += g.image.width + SPACING
        row_height = max(row_height, g.image.height)
    used_width = max(g.x + g.image.width for g in glyphs)
    page = Image.new("L", (used_width, y + row_height), 0)
    for g in glyphs:
        if g.image.width and g.image.height:
            page.paste(g.image, (g.x, g.y))
    return page


# --- Output ---------------------------------------------------------------------

def write_fnt(file: str, face: str, size: int, glyphs: list[Glyph], metrics: Metrics,
              page: Image.Image) -> None:
    """Text BMFont with single spaces only: the compiler splits tokens on one space."""
    lines = [
        f'info face="{face}" size={size} bold=0 italic=0 charset="" unicode=1 '
        f"stretchH=100 smooth=1 aa=1 padding=0,0,0,0 spacing={SPACING},{SPACING} outline=0",
        f"common lineHeight={metrics.line_height} base={metrics.base} "
        f"scaleW={page.width} scaleH={page.height} pages=1 packed=0",
        f'page id=0 file="{file}.png"',
        f"chars count={len(glyphs)}",
    ]
    for g in glyphs:
        lines.append(
            f"char id={ord(g.char)} x={g.x} y={g.y} width={g.image.width} "
            f"height={g.image.height} xoffset={g.xoffset} yoffset={g.yoffset} "
            f"xadvance={g.xadvance} page=0 chnl=15")
    (FONT_DIR / f"{file}.fnt").write_text("\n".join(lines) + "\n")
    page.save(FONT_DIR / f"{file}.png", optimize=True)


def filter_attr(glyphs: str) -> str:
    out = []
    for c in glyphs:
        if " " <= c <= "~" and c not in '"&<>\\':
            out.append(c)
        elif ord(c) <= 0xFFFF:
            out.append(f"\\u{ord(c):04X}")
        else:
            raise SystemExit(f"filter cannot hold {c!r} (outside the BMP)")
    return "".join(out)


def write_fonts_xml() -> None:
    lines = ["<!-- Generated by tools/fontgen/generate.py. Do not edit. -->", "<fonts>"]
    fonts = [(spec.resource_id, spec.file, spec.glyphs) for spec in FONTS]
    fonts.append((ICON_FONT_ID, ICON_FONT_FILE, "".join(chr(icon.code_point) for icon in ICONS)))
    for resource_id, file, glyphs in fonts:
        lines.append(f'    <font id="{resource_id}" filename="{file}.fnt" '
                     f'antialias="true" filter="{filter_attr(glyphs)}"/>')
    lines.append("</fonts>")
    (FONT_DIR / "fonts.xml").write_text("\n".join(lines) + "\n")


def monkey_char(c: str) -> str:
    if c == "'" or c == "\\":
        return f"'\\{c}'"
    if " " <= c <= "~":
        return f"'{c}'"
    return f"(0x{ord(c):04X}).toChar()"


def monkey_string(text: str) -> str:
    """A Monkey C String expression: printable ASCII as literals, anything
    else as (0xXXXX).toChar(), concatenated onto a String."""
    parts, literal = [], ""
    for c in text:
        if " " <= c <= "~" and c not in '"\\':
            literal += c
            continue
        if literal:
            parts.append(f'"{literal}"')
            literal = ""
        parts.append(monkey_char(c))
    if literal:
        parts.append(f'"{literal}"')
    if not parts or not parts[0].startswith('"'):
        parts.insert(0, '""')
    return " + ".join(parts)


@dataclass
class CatalogEntry:
    font_id: str
    resource_id: str
    description: str
    glyphs: list[Glyph]
    metrics: Metrics
    letter_spacing: int


def write_catalog(entries: list[CatalogEntry]) -> None:
    lines = [
        "// Generated by tools/fontgen/generate.py. Do not edit; run scripts/gen-fonts.sh.",
        "import Toybox.Lang;",
        "",
        "// Every generated font, by its index in FontCatalog.entries().",
        "enum FontId {",
    ]
    lines += [f"    FONT_{e.font_id}{',' if i < len(entries) - 1 else ''}"
              for i, e in enumerate(entries)]
    lines += [
        "}",
        "",
        "// One generated font, described once. FaceModel measures and places",
        "// text with it; the renderer loads and draws the same font from it.",
        "class FontEntry {",
        "    // Rez.Fonts.<name>, loaded by the renderer.",
        "    public var resource as ResourceId;",
        "    public var name as String;",
        "    // Every glyph in the font (its resource filter), in order.",
        "    public var glyphs as String;",
        "    // Every glyph's xadvance exactly as written to its .fnt, so measured",
        "    // and drawn widths agree.",
        "    public var widths as Dictionary<Char, Number>;",
        "    // The BMFont base (line top to baseline, px) and the cap height (px).",
        "    public var base as Number;",
        "    public var capHeight as Number;",
        "    // Letter spacing baked into every xadvance, the last glyph's too (px).",
        "    public var letterSpacing as Number;",
        "",
        "    function initialize(resource as ResourceId, name as String, glyphs as String,",
        "            widths as Dictionary<Char, Number>, base as Number, capHeight as Number,",
        "            letterSpacing as Number) {",
        "        self.resource = resource;",
        "        self.name = name;",
        "        self.glyphs = glyphs;",
        "        self.widths = widths;",
        "        self.base = base;",
        "        self.capHeight = capHeight;",
        "        self.letterSpacing = letterSpacing;",
        "    }",
        "",
        "    // Whether the font has a glyph for c.",
        "    function hasGlyph(c as Char) as Boolean {",
        "        return glyphs.find(c.toString()) != null;",
        "    }",
        "}",
        "",
        "module FontCatalog {",
        "    // Icons are one glyph each in the icon font,",
        f"    // {ICON_SIZE} px square, at these Private Use Area code points.",
    ]
    lines += [f"    const ICON_{icon.name} = 0x{icon.code_point:04X};" for icon in ICONS]
    lines += [
        "",
        "    // Built on first use, then kept.",
        "    var _entries as Array<FontEntry>? = null;",
        "",
        "    function entry(id as FontId) as FontEntry {",
        "        return entries()[id as Number];",
        "    }",
        "",
        "    // Every font, indexed by FontId.",
        "    function entries() as Array<FontEntry> {",
        "        var all = _entries;",
        "        if (all == null) {",
        "            all = [",
    ]
    for i, e in enumerate(entries):
        widths = ", ".join(f"{monkey_char(g.char)} => {g.xadvance}" for g in e.glyphs)
        glyph_set = monkey_string("".join(g.char for g in e.glyphs))
        lines += [
            f"                // {e.description}",
            f"                new FontEntry(Rez.Fonts.{e.resource_id}, \"{e.resource_id}\",",
            f"                    {glyph_set},",
            f"                    {{ {widths} }} as Dictionary<Char, Number>,",
            f"                    {e.metrics.base}, {e.metrics.cap_height}, {e.letter_spacing})"
            f"{',' if i < len(entries) - 1 else ''}",
        ]
    lines += [
        "            ] as Array<FontEntry>;",
        "            _entries = all;",
        "        }",
        "        return all;",
        "    }",
        "}",
    ]
    CATALOG_FILE.write_text("\n".join(lines) + "\n")


def main() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        gf = GoogleFonts(Path(tmp))
        sources = {key: SOURCES[key](gf) for key in {spec.source for spec in FONTS}}

        FONT_DIR.mkdir(parents=True, exist_ok=True)
        results = []
        for spec in FONTS:
            src = sources[spec.source]
            glyphs, metrics = render_font(spec, src)
            page = pack(glyphs)
            write_fnt(spec.file, src.face, spec.size, glyphs, metrics, page)
            results.append((spec, src, glyphs, metrics))
        icons, icon_metrics = render_icons()
        write_fnt(ICON_FONT_FILE, ICON_FONT_ID, ICON_SIZE, icons, icon_metrics, pack(icons))

        for src in sources.values():
            (FONT_DIR / f"OFL-{src.license_name}.txt").write_bytes(src.license_text)
        write_fonts_xml()
        catalog = [CatalogEntry(spec.font_id, spec.resource_id,
                                f"{src.face} {spec.size} px.", glyphs, metrics, spec.tracking)
                   for spec, src, glyphs, metrics in results]
        catalog.append(CatalogEntry(ICON_FONT_CATALOG_ID, ICON_FONT_ID,
                                    f"The icon font, {ICON_SIZE} px.", icons, icon_metrics, 0))
        write_catalog(catalog)

        for key, src in sources.items():
            print(f"source {key}: {src.origin}")
        for spec, src, glyphs, metrics in results:
            advances = " ".join(f"{g.char}={g.xadvance}" for g in glyphs)
            zero = next((g for g in glyphs if g.char == "0"), None)
            ink = f", '0' ink {zero.image.height} px" if zero else ""
            print(f"{spec.file}: base {metrics.base}, lineHeight {metrics.line_height}, "
                  f"cap {metrics.cap_height}"
                  f"{ink}; {advances}")
        for icon, glyph in zip(ICONS, icons):
            print(f"{ICON_FONT_FILE}: {icon.name} U+{icon.code_point:04X}, ink "
                  f"{glyph.image.width}x{glyph.image.height} at ({glyph.xoffset}, {glyph.yoffset})")


if __name__ == "__main__":
    sys.exit(main())
