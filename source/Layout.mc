import Toybox.Lang;

// Fixed geometry from the final design, on the 416x416 canvas.
module Layout {
    const CENTER_X = 208;
    const CENTER_Y = 208;

    // The bezel ring, on the screen's edge.
    const BEZEL_RADIUS = 204;
    const BEZEL_PEN = 8;

    // The background disc.
    const DISC_RADIUS = 194;

    // Width of the black well around an element.
    const WELL = 6;

    // The time band: a rounded rect filled with the accent.
    const BAND_X = 72;
    const BAND_Y = 80;
    const BAND_W = 272;
    const BAND_H = 64;
    const BAND_RADIUS = 20;

    // The date pill, overlapping the bottom edge of the time band: centered
    // on CENTER_X, from DATE_PILL_MIN_WIDTH up to the band's width (Q23, Q33).
    // The date's capitals are vertically centered on DATE_CENTER_Y.
    const DATE_PILL_Y = 140;
    const DATE_PILL_HEIGHT = 28;
    const DATE_PILL_RADIUS = 14;
    // Also in tools/fontgen/generate.py, which derives GlyphWidths.DATE_PAD
    // from it; change both and regenerate.
    const DATE_PILL_MIN_WIDTH = 96;
    const DATE_PILL_MAX_WIDTH = BAND_W;
    const DATE_CENTER_Y = 154;

    // The time: centered on this x, with its baseline on this y.
    const TIME_CENTER_X = CENTER_X;
    const TIME_BASELINE_Y = 135;

    // The battery bar, in design degrees (0 = 12 o'clock, clockwise).
    // Segment i spans BATTERY_FIRST + i * BATTERY_STEP for BATTERY_SEGMENT
    // degrees: the design's 5.36 deg segments and 1.6 deg gaps, rounded to
    // whole degrees on purpose.
    const BATTERY_RADIUS = 180;
    const BATTERY_PEN = 4;
    const BATTERY_SEGMENTS = 10;
    const BATTERY_FIRST = -34;
    const BATTERY_STEP = 7;
    const BATTERY_SEGMENT = 5;
    // The battery well: an arc from -BATTERY_WELL_HALF to +BATTERY_WELL_HALF
    // with a round cap (radius pen / 2) at each end.
    const BATTERY_WELL_HALF = 36;
    const BATTERY_WELL_PEN = 12;
}
