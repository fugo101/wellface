import Toybox.Lang;

// The geometry of a round field: its circle, the gauge ring inside it, and
// where its icon and number go. A field is only a place; the metric shown in
// it decides what is drawn there (Q29).
class RoundField {
    // The field's circle; its well is a circle of radius + Layout.WELL.
    public var x as Number;
    public var y as Number;
    public var radius as Number;
    // The gauge ring's centerline radius and pen.
    public var gaugeRadius as Number;
    public var gaugePen as Number;
    // The icon's top-left corner (icons are 24 px square).
    public var iconX as Number;
    public var iconY as Number;
    // The number is centered on x, its digits vertically centered on this y.
    public var numberY as Number;

    function initialize(x as Number, y as Number, radius as Number, gaugeRadius as Number,
            gaugePen as Number, iconX as Number, iconY as Number, numberY as Number) {
        self.x = x;
        self.y = y;
        self.radius = radius;
        self.gaugeRadius = gaugeRadius;
        self.gaugePen = gaugePen;
        self.iconX = iconX;
        self.iconY = iconY;
        self.numberY = numberY;
    }
}

// Fixed geometry from the final design, on the 416x416 canvas, and the
// static MVP mapping of metrics to fields.
module Layout {
    // The one place that says which metric each field shows (Q29). Fields
    // will become switchable later; only these lines change then.
    const LEFT_METRIC = METRIC_STRESS;
    const CENTER_METRIC = METRIC_BODY_BATTERY;
    const RIGHT_METRIC = METRIC_HEART_RATE;
    const BOTTOM_METRIC = METRIC_STEPS;
    // The bezel ring only takes a goal metric: one with a goal read from the
    // watch (FaceModel.goalOf). Steps is the only one in the MVP.
    const BEZEL_METRIC = METRIC_STEPS;

    const CENTER_X = 208;
    const CENTER_Y = 208;

    // The center field.
    const CENTER_FIELD_X = 208;
    const CENTER_FIELD_Y = 246;
    const CENTER_FIELD_RADIUS = 60;
    // The design's gauge centerline is r 55.5. With pen 9, r 56 lands on
    // about r 50.4-59.5 in the simulator (design 51-60); r 55 lands 1 px
    // further in.
    const CENTER_GAUGE_RADIUS = 56;
    const CENTER_GAUGE_PEN = 9;
    const CENTER_ICON_X = 196;
    const CENTER_ICON_Y = 203;
    const CENTER_NUMBER_Y = 258;

    function centerField() as RoundField {
        return new RoundField(CENTER_FIELD_X, CENTER_FIELD_Y, CENTER_FIELD_RADIUS,
            CENTER_GAUGE_RADIUS, CENTER_GAUGE_PEN, CENTER_ICON_X, CENTER_ICON_Y,
            CENTER_NUMBER_Y);
    }

    // The bezel ring, on the screen's edge.
    const BEZEL_RADIUS = 204;
    const BEZEL_PEN = 8;
    // The dot at the head of the step progress, centered on the ring.
    const BEZEL_HEAD_RADIUS = 4;
    // Notches across the ring at 3, 6 and 9 o'clock, in design degrees.
    const BEZEL_NOTCHES = [90, 180, 270] as Array<Number>;
    const BEZEL_NOTCH_INNER = 198;
    const BEZEL_NOTCH_OUTER = 210;
    const BEZEL_NOTCH_PEN = 3;

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
