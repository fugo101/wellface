"""Font generator for Wellface.

Downloads the source fonts fresh from Google Fonts (the google/fonts
repository), renders the bitmap fonts the face uses and writes:

- resources/fonts/<name>.fnt + <name>.png: text BMFont, one 8-bit grayscale
  page per font, white on black (the compiler reads coverage as brightness);
- resources/fonts/fonts.xml: the font resources, antialiased, with a filter;
- resources/fonts/OFL-<family>.txt: the license of every source font used;
- source/GlyphWidths.mc: the glyph-width tables FaceModel measures text with,
  holding exactly the xadvance values written to each .fnt.

Run it with scripts/gen-fonts.sh. To add a font, add an entry to FONTS.
"""

from __future__ import annotations

import json
import re
import sys
import tempfile
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass
from pathlib import Path

from fontTools.pens.boundsPen import BoundsPen
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer
from PIL import Image, ImageChops, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
FONT_DIR = ROOT / "resources" / "fonts"
TABLES_FILE = ROOT / "source" / "GlyphWidths.mc"

REPO_API = "https://api.github.com/repos/google/fonts"
RAW = "https://raw.githubusercontent.com/google/fonts"

# Glyphs are rendered at this multiple of the target size and box-filtered
# down, so the fill and the outline come from the same unhinted geometry.
SUPERSAMPLE = 4
# Empty pixels kept around each glyph while rendering (1x).
MARGIN = 4
# Width of the texture page and the gap between glyphs on it.
PAGE_WIDTH = 256
SPACING = 1

DIGITS = "0123456789"


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
    """Reads google/fonts at one commit, so every file comes from the same tree."""

    def __init__(self, work: Path):
        self.work = work
        self.sha = _get(f"{REPO_API}/commits/main",
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


SOURCES = {
    "big-shoulders-display-800": big_shoulders_display_extrabold,
}


# --- Fonts to generate ----------------------------------------------------------

@dataclass
class FontSpec:
    resource_id: str  # Rez.Fonts.<resource_id>
    file: str         # resources/fonts/<file>.fnt and .png
    table: str        # GlyphWidths.<table> and GlyphWidths.<table>_BASE
    source: str       # key in SOURCES
    size: int         # pixels per em
    glyphs: str
    tabular_digits: bool = False
    outline: int = 0  # > 0: keep only this many px inside the edge (fill minus erosion)
    tracking: int = 0  # px added to every xadvance (baked-in letter spacing)
    digit_height: float | None = None  # asserted height of "0" in px, +-1


FONTS = [
    FontSpec("TimeFilled", "time57", "TIME", "big-shoulders-display-800", 57,
             DIGITS + ":", tabular_digits=True, digit_height=46),
    FontSpec("TimeOutline", "time57outline", "TIME_OUTLINE", "big-shoulders-display-800", 57,
             DIGITS + ":", tabular_digits=True, outline=2, digit_height=46),
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
    metrics = Metrics(line_height=round((hhea.ascent - hhea.descent) * scale), base=base)

    if spec.digit_height is not None:
        pen = BoundsPen(glyph_set)
        glyph_set[cmap[ord("0")]].draw(pen)
        _, y_min, _, y_max = pen.bounds
        height = (y_max - y_min) * scale
        if abs(height - spec.digit_height) > 1:
            raise SystemExit(f"{spec.file}: '0' is {height:.2f} px tall, "
                             f"expected {spec.digit_height} +-1")

    advances = {c: round(tt["hmtx"][cmap[ord(c)]][0] * scale) for c in spec.glyphs}
    widest_digit = max((advances[c] for c in spec.glyphs if c in DIGITS), default=0)

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
        if spec.outline:
            big = ImageChops.subtract(big, erode(big, spec.outline * ss))
        image = big.reduce(ss)

        bbox = image.getbbox()
        if bbox is None:
            raise SystemExit(f"{spec.file}: glyph {c!r} renders empty")
        shift = 0
        if spec.tabular_digits and c in DIGITS:
            shift = (widest_digit - advance) // 2
            advance = widest_digit
        glyphs.append(Glyph(
            char=c,
            image=image.crop(bbox),
            xoffset=bbox[0] - origin_x + shift,
            yoffset=bbox[1] - (origin_y - base),
            xadvance=advance + spec.tracking,
        ))
    return glyphs, metrics


def erode(image: Image.Image, radius: int) -> Image.Image:
    """Grayscale erosion with a disc: each pixel becomes the minimum of its
    neighbourhood, so the shape shrinks by `radius` px on every side."""
    pad = radius + 1
    padded = Image.new("L", (image.width + 2 * pad, image.height + 2 * pad), 0)
    padded.paste(image, (pad, pad))
    result = padded
    for dy in range(-radius, radius + 1):
        for dx in range(-radius, radius + 1):
            if (dx or dy) and dx * dx + dy * dy <= radius * radius:
                result = ImageChops.darker(result, ImageChops.offset(padded, dx, dy))
    return result.crop((pad, pad, pad + image.width, pad + image.height))


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
        page.paste(g.image, (g.x, g.y))
    return page


# --- Output ---------------------------------------------------------------------

def write_fnt(spec: FontSpec, src: SourceFont, glyphs: list[Glyph], metrics: Metrics,
              page: Image.Image) -> None:
    """Text BMFont with single spaces only: the compiler splits tokens on one space."""
    lines = [
        f'info face="{src.face}" size={spec.size} bold=0 italic=0 charset="" unicode=1 '
        f"stretchH=100 smooth=1 aa=1 padding=0,0,0,0 spacing={SPACING},{SPACING} outline=0",
        f"common lineHeight={metrics.line_height} base={metrics.base} "
        f"scaleW={page.width} scaleH={page.height} pages=1 packed=0",
        f'page id=0 file="{spec.file}.png"',
        f"chars count={len(glyphs)}",
    ]
    for g in glyphs:
        lines.append(
            f"char id={ord(g.char)} x={g.x} y={g.y} width={g.image.width} "
            f"height={g.image.height} xoffset={g.xoffset} yoffset={g.yoffset} "
            f"xadvance={g.xadvance} page=0 chnl=15")
    (FONT_DIR / f"{spec.file}.fnt").write_text("\n".join(lines) + "\n")
    page.save(FONT_DIR / f"{spec.file}.png", optimize=True)


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
    for spec in FONTS:
        lines.append(f'    <font id="{spec.resource_id}" filename="{spec.file}.fnt" '
                     f'antialias="true" filter="{filter_attr(spec.glyphs)}"/>')
    lines.append("</fonts>")
    (FONT_DIR / "fonts.xml").write_text("\n".join(lines) + "\n")


def monkey_char(c: str) -> str:
    if c == "'" or c == "\\":
        return f"'\\{c}'"
    if " " <= c <= "~":
        return f"'{c}'"
    return f"(0x{ord(c):04X}).toChar()"


def write_tables(results: list[tuple[FontSpec, SourceFont, list[Glyph], Metrics]]) -> None:
    lines = [
        "// Generated by tools/fontgen/generate.py. Do not edit; run scripts/gen-fonts.sh.",
        "import Toybox.Lang;",
        "",
        "// Per font: the BMFont base (line top to baseline, px) and every glyph's",
        "// xadvance exactly as written to its .fnt, so measured and drawn widths agree.",
        "module GlyphWidths {",
    ]
    for spec, src, glyphs, metrics in results:
        entries = ", ".join(f"{monkey_char(g.char)} => {g.xadvance}" for g in glyphs)
        lines += [
            f"    // {spec.resource_id}: {src.face} {spec.size} px.",
            f"    const {spec.table}_BASE = {metrics.base};",
            f"    const {spec.table} = {{ {entries} }} as Dictionary<Char, Number>;",
        ]
    lines.append("}")
    TABLES_FILE.write_text("\n".join(lines) + "\n")


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
            write_fnt(spec, src, glyphs, metrics, page)
            results.append((spec, src, glyphs, metrics))

        for src in sources.values():
            (FONT_DIR / f"OFL-{src.license_name}.txt").write_bytes(src.license_text)
        write_fonts_xml()
        write_tables(results)

        for key, src in sources.items():
            print(f"source {key}: {src.origin}")
        for spec, src, glyphs, metrics in results:
            advances = " ".join(f"{g.char}={g.xadvance}" for g in glyphs)
            zero = next((g for g in glyphs if g.char == "0"), None)
            ink = f", '0' ink {zero.image.height} px" if zero else ""
            print(f"{spec.file}: base {metrics.base}, lineHeight {metrics.line_height}"
                  f"{ink}; {advances}")


if __name__ == "__main__":
    sys.exit(main())
