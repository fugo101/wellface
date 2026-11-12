import Toybox.Lang;

// The geometry of a round field: its circle, the ring inside it, and
// where its icon and number go. A field is only a place; the metric shown in
// it decides what is drawn there (Q29).
class RoundField {
    // The field's circle; its well is a circle of radius + Layout.WELL.
    public var x as Number;
    public var y as Number;
    public var radius as Number;
    // The ring inside the field (a gauge or zone segments): its centerline
    // radius and pen.
    public var ringRadius as Number;
    public var ringPen as Number;
    // The icon's top-left corner (icons are 24 px square).
    public var iconX as Number;
    public var iconY as Number;
    // The number is centered on x, its digits vertically centered on this y.
    public var numberY as Number;
    // The center field's large number (always 48 px), rather than one that
    // shrinks with more characters (FaceModel.numberFontFor).
    public var largeNumber as Boolean;

    function initialize(x as Number, y as Number, radius as Number, ringRadius as Number,
            ringPen as Number, iconX as Number, iconY as Number, numberY as Number,
            largeNumber as Boolean) {
        self.x = x;
        self.y = y;
        self.radius = radius;
        self.ringRadius = ringRadius;
        self.ringPen = ringPen;
        self.iconX = iconX;
        self.iconY = iconY;
        self.numberY = numberY;
        self.largeNumber = largeNumber;
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

    // The left field. Its gauge sits on the design's ring centerline,
    // r 38 - 6 / 2; the icon's top-left is (x - 12, y - 30).
    const LEFT_FIELD_X = 88;
    const LEFT_FIELD_Y = 236;
    const LEFT_FIELD_RADIUS = 38;
    const LEFT_RING_RADIUS = 35;
    const LEFT_RING_PEN = 6;
    const LEFT_ICON_X = 76;
    const LEFT_ICON_Y = 206;
    const LEFT_NUMBER_Y = 250;

    function leftField() as RoundField {
        return new RoundField(LEFT_FIELD_X, LEFT_FIELD_Y, LEFT_FIELD_RADIUS, LEFT_RING_RADIUS,
            LEFT_RING_PEN, LEFT_ICON_X, LEFT_ICON_Y, LEFT_NUMBER_Y, false);
    }

    // The right field, laid out like the left one.
    const RIGHT_FIELD_X = 328;
    const RIGHT_FIELD_Y = 236;
    const RIGHT_FIELD_RADIUS = 38;
    const RIGHT_RING_RADIUS = 35;
    const RIGHT_RING_PEN = 6;
    const RIGHT_ICON_X = 316;
    const RIGHT_ICON_Y = 206;
    const RIGHT_NUMBER_Y = 250;

    function rightField() as RoundField {
        return new RoundField(RIGHT_FIELD_X, RIGHT_FIELD_Y, RIGHT_FIELD_RADIUS,
            RIGHT_RING_RADIUS, RIGHT_RING_PEN, RIGHT_ICON_X, RIGHT_ICON_Y, RIGHT_NUMBER_Y, false);
    }

    // Zone segments, in design degrees: segment i (zone i + 1) spans
    // i x ZONE_STEP + ZONE_GAP for ZONE_SWEEP degrees, so 4 to 68 for zone 1.
    const ZONE_SEGMENTS = 5;
    const ZONE_STEP = 72;
    const ZONE_GAP = 4;
    const ZONE_SWEEP = 64;

    // Icons are square glyphs in the icon font.
    const ICON_SIZE = 24;

    // The bottom field: a pill, black or (goal reached) the accent, that is
    // its own well.
    const BOTTOM_X = 126;
    const BOTTOM_Y = 320;
    const BOTTOM_W = 164;
    const BOTTOM_H = 40;
    const BOTTOM_RADIUS = 20;
    // Goal not reached: the icon's top-left, the number right-aligned on
    // BOTTOM_NUMBER_RIGHT and "/ goal" left-aligned on BOTTOM_GOAL_LEFT (a
    // 5 px gap). The digits are centered on BOTTOM_NUMBER_Y, the goal on
    // BOTTOM_GOAL_Y.
    const BOTTOM_ICON_X = 140;
    const BOTTOM_ICON_Y = 328;
    const BOTTOM_NUMBER_RIGHT = 228;
    const BOTTOM_GOAL_LEFT = 233;
    const BOTTOM_NUMBER_Y = 340;
    const BOTTOM_GOAL_Y = 341;
    // The anchored text fits when the number starts at or after
    // BOTTOM_NUMBER_MIN_LEFT (4 px past the foot's ink, which ends at x 160)
    // and the goal ends at or before BOTTOM_GOAL_MAX_RIGHT (4 px inside the
    // pill's rounded end).
    const BOTTOM_NUMBER_MIN_LEFT = 164;
    const BOTTOM_GOAL_MAX_RIGHT = 286;
    // A centered group (icon hidden, or goal reached) stays within these.
    const BOTTOM_GROUP_LEFT = 140;
    const BOTTOM_GROUP_RIGHT = 276;
    // Goal reached: the gap between the icon's 24 px box and the number.
    const BOTTOM_REACHED_GAP = 4;

    // The center field.
    const CENTER_FIELD_X = 208;
    const CENTER_FIELD_Y = 246;
    const CENTER_FIELD_RADIUS = 60;
    // The design's gauge centerline is r 55.5. With pen 9, r 56 lands on
    // about r 50.4-59.5 in the simulator (design 51-60); r 55 lands 1 px
    // further in.
    const CENTER_RING_RADIUS = 56;
    const CENTER_RING_PEN = 9;
    const CENTER_ICON_X = 196;
    const CENTER_ICON_Y = 203;
    const CENTER_NUMBER_Y = 258;

    function centerField() as RoundField {
        return new RoundField(CENTER_FIELD_X, CENTER_FIELD_Y, CENTER_FIELD_RADIUS,
            CENTER_RING_RADIUS, CENTER_RING_PEN, CENTER_ICON_X, CENTER_ICON_Y,
            CENTER_NUMBER_Y, true);
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

    // Always On: the pen of the AOD outlines (Q12): the date pill's outline here, the
    // time's outline baked into the outline time font.
    const AOD_PEN = 2;
    // The burn-in shift (Q28): the AOD time and date move by one [x, y]
    // offset (px) per minute, offset (minute of the hour mod 12). 12 divides
    // 60, so minute 59 steps to minute 0 like any other minute. Each step
    // moves at least 3 px on both axes, and no 3 consecutive offsets repeat
    // or lie on one line; the 12 offsets spread over the +-4 px square.
    const AOD_OFFSETS = [
        [-4, -4], [1, -1], [4, 4], [-4, -1], [-1, 2], [4, -3],
        [-2, 0], [1, 3], [4, 0], [-4, 3], [-1, -4], [3, 2]
    ] as Array<Array<Number> >;

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
