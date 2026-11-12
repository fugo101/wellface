import Toybox.Lang;
import Toybox.Math;

// The data a frame is computed from. Built by the data reader from the
// watch's clock and sensors; FaceModel never reads them itself.
class Snapshot {
    // Clock part, read on every update that is not OFF.
    // 0-23, whatever the watch's 12/24 h setting is (Q22).
    public var hour as Number;
    public var minute as Number;
    // Day of month, 1-31.
    public var day as Number = 1;
    // Weekday number from FORMAT_SHORT: 1 = Sunday ... 7 = Saturday.
    public var weekdayNumber as Number = 1;
    // The localized weekday name from FORMAT_MEDIUM, as the watch returns it.
    public var weekdayName as String? = null;

    // Sensor part, read once a minute in high power. Null means missing.
    // Watch battery in percent, already rounded and clamped to 0-100.
    public var battery as Number? = null;
    // Today's steps and the watch's own daily step goal (auto goal, never
    // entered by hand).
    public var steps as Number? = null;
    public var stepGoal as Number? = null;
    // Body Battery, 0-100 (the data reader drops non-Number and negative
    // values).
    public var bodyBattery as Number? = null;
    // Stress, 0-100 (same rule).
    public var stress as Number? = null;

    function initialize(hour as Number, minute as Number) {
        self.hour = hour;
        self.minute = minute;
    }
}

// What to draw on top of the static layer: every string, color and arc the
// renderer needs. FaceModel fills in every field; the defaults only exist to
// satisfy the type checker.
class Frame {
    public var time as String = "";
    // Width of the time in the time font, from its glyph-width table.
    public var timeWidth as Number = 0;
    // Top-left corner to draw the time from (left-justified, line top).
    public var timeX as Number = 0;
    public var timeY as Number = 0;
    public var timeColor as Number = 0;
    // The date text, for example "THU 12", its width in the date font and
    // the top-left corner to draw it from (left-justified, line top).
    public var date as String = "";
    public var dateWidth as Number = 0;
    public var dateX as Number = 0;
    public var dateY as Number = 0;
    public var dateColor as Number = 0;
    // The black pill behind the date; its width follows the text.
    public var datePill as RoundedRect = new RoundedRect(0, 0, 0, 0, 0, 0);
    // The lit battery segments only, leftmost first. The static layer holds
    // all ten unlit ones underneath.
    public var batteryLit as Array<Arc> = [] as Array<Arc>;
    // Step progress on the bezel ring, over the static track. Sweep 0 when
    // there is no progress to show.
    public var bezelProgress as Arc = new Arc(0, 0, 0, 0, 0, 0, 0, 0);
    // The dot at the head of the progress, null when there is no goal to
    // show progress toward or the steps are missing.
    public var bezelHead as Circle? = null;
    // Goal reached: the goal is above 0, the steps are known and at least
    // the goal. The bottom field switches style on it (ticket 10).
    public var stepGoalReached as Boolean = false;
    // The left and center fields' content.
    public var leftField as FieldFrame = new FieldFrame();
    public var centerField as FieldFrame = new FieldFrame();

    function initialize() {
    }
}

// The generated fonts a field's number can be drawn in. The renderer maps
// each to its loaded font, FaceModel to its glyph-width table.
enum NumberFont {
    NUMBER_FONT_48,
    NUMBER_FONT_26,
    NUMBER_FONT_22,
    NUMBER_FONT_18
}

// A generated font's glyph-width table, base and cap height (from
// GlyphWidths), so FaceModel can measure and place text in it.
class FontMetrics {
    public var widths as Dictionary<Char, Number>;
    public var base as Number;
    public var capHeight as Number;

    function initialize(widths as Dictionary<Char, Number>, base as Number, capHeight as Number) {
        self.widths = widths;
        self.base = base;
        self.capHeight = capHeight;
    }
}

// What a field draws over its static well and track: the lit arcs, the icon
// and the number. Which arcs, colors and strings depends on the metric shown.
class FieldFrame {
    // Drawn over the track. A gauge has one arc, or none when the value is
    // missing or 0.
    public var arcs as Array<Arc> = [] as Array<Arc>;
    // The metric's icon (one glyph in the icon font), its top-left corner
    // and its color.
    public var icon as String = "";
    public var iconX as Number = 0;
    public var iconY as Number = 0;
    public var iconColor as Number = 0;
    // The value as text, its color and font, its measured width and the
    // top-left corner to draw it from (left-justified, line top).
    public var number as String = "";
    public var numberColor as Number = 0;
    public var numberFont as NumberFont = NUMBER_FONT_48;
    public var numberWidth as Number = 0;
    public var numberX as Number = 0;
    public var numberY as Number = 0;

    function initialize() {
    }
}

// The parts of the face that depend only on the theme, so the renderer draws
// them once into a buffer. Its own geometry (disc, time band) is in Layout.
class StaticLayer {
    public var backgroundColor as Number = 0;
    public var wellColor as Number = 0;
    public var timeBandColor as Number = 0;
    public var bezelTrack as Arc = new Arc(0, 0, 0, 0, 0, 0, 0, 0);
    public var batteryWell as Arc = new Arc(0, 0, 0, 0, 0, 0, 0, 0);
    // The round ends of the battery well, left first.
    public var batteryCaps as Array<Circle> = [] as Array<Circle>;
    // The ten battery segments, all unlit, leftmost first.
    public var batteryTrack as Array<Arc> = [] as Array<Arc>;
    // The black wells of the round fields, and the tracks of their gauges.
    public var fieldWells as Array<Circle> = [] as Array<Circle>;
    public var gaugeTracks as Array<Arc> = [] as Array<Arc>;

    function initialize() {
    }
}

// One arc in the arc contract: Connect IQ degrees (0 = 3 o'clock,
// counter-clockwise), integers 0-359, always drawn with ARC_CLOCKWISE from
// start to end, with flat ends. Sweep 0 means no arc; 360 means a full
// circle (then start == end, which drawArc draws as a full circle).
class Arc {
    public var x as Number;
    public var y as Number;
    public var radius as Number;
    public var pen as Number;
    public var start as Number;
    public var end as Number;
    // In degrees, 0-360.
    public var sweep as Number;
    public var color as Number;

    function initialize(x as Number, y as Number, radius as Number, pen as Number,
            start as Number, end as Number, sweep as Number, color as Number) {
        self.x = x;
        self.y = y;
        self.radius = radius;
        self.pen = pen;
        self.start = start;
        self.end = end;
        self.sweep = sweep;
        self.color = color;
    }
}

// A filled rounded rectangle.
class RoundedRect {
    public var x as Number;
    public var y as Number;
    public var width as Number;
    public var height as Number;
    public var radius as Number;
    public var color as Number;

    function initialize(x as Number, y as Number, width as Number, height as Number,
            radius as Number, color as Number) {
        self.x = x;
        self.y = y;
        self.width = width;
        self.height = height;
        self.radius = radius;
        self.color = color;
    }
}

// A straight line from (x1, y1) to (x2, y2).
class Line {
    public var x1 as Number;
    public var y1 as Number;
    public var x2 as Number;
    public var y2 as Number;
    public var pen as Number;
    public var color as Number;

    function initialize(x1 as Number, y1 as Number, x2 as Number, y2 as Number,
            pen as Number, color as Number) {
        self.x1 = x1;
        self.y1 = y1;
        self.x2 = x2;
        self.y2 = y2;
        self.pen = pen;
        self.color = color;
    }
}

// A filled circle.
class Circle {
    public var x as Number;
    public var y as Number;
    public var radius as Number;
    public var color as Number;

    function initialize(x as Number, y as Number, radius as Number, color as Number) {
        self.x = x;
        self.y = y;
        self.radius = radius;
        self.color = color;
    }
}

// Pure display rules: no sensor, graphics or resource dependencies.
// This is the face's only test seam.
module FaceModel {
    // Indexed by the FORMAT_SHORT weekday number - 1 (1 = Sunday).
    const ENGLISH_WEEKDAYS = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"] as Array<String>;

    // Base letters for U+00C0-U+00FF and U+0100-U+017F, one per code point;
    // "?" means the date font cannot show it (for example AE, the
    // multiplication sign, thorn, sharp s, IJ, OE). Letters with a stroke
    // fold to their base letter too (D for the Vietnamese D with stroke).
    const LATIN_1_BASE = "AAAAAA?CEEEEIIIIDNOOOOO?OUUUUY??AAAAAA?CEEEEIIIIDNOOOOO?OUUUUY?Y";
    const LATIN_EXTENDED_A_BASE =
        "AAAAAACCCCCCCCDDDDEEEEEEEEEEGGGGGGGGHHHHIIIIIIIIII??JJKK?LLLLLLLLLL" +
        "NNNNNN?NNOOOOOO??RRRRRRSSSSSSSSTTTTTTUUUUUUUUUUUUWWYYYZZZZZZS";

    function compute(snapshot as Snapshot, theme as Theme) as Frame {
        var frame = new Frame();
        frame.time = formatTime(snapshot.hour, snapshot.minute);
        frame.timeWidth = textWidth(frame.time, GlyphWidths.TIME);
        frame.timeX = Layout.TIME_CENTER_X - frame.timeWidth / 2;
        frame.timeY = Layout.TIME_BASELINE_Y - GlyphWidths.TIME_BASE;
        frame.timeColor = theme.ink;
        frame.batteryLit = batteryLit(snapshot.battery, theme);

        // The bezel ring: progress of its goal metric toward the goal.
        var bezelValue = metricValue(Layout.BEZEL_METRIC, snapshot);
        var bezelGoal = goalOf(Layout.BEZEL_METRIC, snapshot);
        var sweep = bezelSweep(bezelValue, bezelGoal);
        frame.bezelProgress = arc(Layout.CENTER_X, Layout.CENTER_Y, Layout.BEZEL_RADIUS,
            Layout.BEZEL_PEN, 0, sweep, theme.accent);
        if (hasGoalProgress(bezelValue, bezelGoal)) {
            frame.bezelHead = circleAt(sweep, Layout.BEZEL_RADIUS, Layout.BEZEL_HEAD_RADIUS,
                theme.text);
        }
        frame.stepGoalReached = goalReached(metricValue(Layout.BOTTOM_METRIC, snapshot),
            goalOf(Layout.BOTTOM_METRIC, snapshot));

        frame.leftField = roundField(Layout.leftField(), Layout.LEFT_METRIC, snapshot, theme);
        frame.centerField = roundField(Layout.centerField(), Layout.CENTER_METRIC, snapshot,
            theme);
        frame.date = dateText(snapshot);
        frame.dateWidth = textWidth(frame.date, GlyphWidths.DATE);
        frame.dateX = Layout.CENTER_X - frame.dateWidth / 2;
        // Upper case only, so the capitals are centered, as in the design.
        frame.dateY = Layout.DATE_CENTER_Y + GlyphWidths.DATE_CAP_HEIGHT / 2 - GlyphWidths.DATE_BASE;
        frame.dateColor = theme.text;
        var pillWidth = datePillWidth(frame.dateWidth);
        frame.datePill = new RoundedRect(Layout.CENTER_X - pillWidth / 2, Layout.DATE_PILL_Y,
            pillWidth, Layout.DATE_PILL_HEIGHT, Layout.DATE_PILL_RADIUS, theme.ink);
        return frame;
    }

    // A round field showing `metric`. The metric decides the style; every
    // MVP metric in a round field so far is a gauge.
    function roundField(field as RoundField, metric as Metric, snapshot as Snapshot,
            theme as Theme) as FieldFrame {
        return gaugeField(field, metric, metricValue(metric, snapshot), theme);
    }

    // A gauge: an arc from 12 o'clock, clockwise, over the field's track. In
    // warning, the arc and number take the warning color.
    function gaugeField(field as RoundField, metric as Metric, value as Number?,
            theme as Theme) as FieldFrame {
        var content = new FieldFrame();
        var icon = iconOf(metric);
        content.icon = icon != null ? icon.toChar().toString() : "";
        content.iconX = field.iconX;
        content.iconY = field.iconY;
        content.iconColor = theme.secondary;
        content.number = "--";
        content.numberColor = theme.secondary;
        if (value != null) {
            content.number = value.toString();
            content.numberColor = theme.text;
            var arcColor = theme.accent;
            var warning = warningColor(metric, value, theme);
            if (warning != null) {
                content.iconColor = warning;
                content.numberColor = warning;
                arcColor = warning;
            }
            var sweep = gaugeSweep(value);
            if (sweep > 0) {
                content.arcs = [arc(field.x, field.y, field.gaugeRadius, field.gaugePen, 0, sweep,
                    arcColor)] as Array<Arc>;
            }
        }
        content.numberFont = numberFontFor(field, content.number);
        var metrics = numberMetrics(content.numberFont);
        content.numberWidth = textWidth(content.number, metrics.widths);
        content.numberX = field.x - content.numberWidth / 2;
        // Digits only, so their cap height is centered on numberY.
        content.numberY = field.numberY + metrics.capHeight / 2 - metrics.base;
        return content;
    }

    // The center field's number is always 48 px. The left and right numbers
    // shrink with more characters: <= 3 -> 26, 4 -> 22, >= 5 -> 18.
    function numberFontFor(field as RoundField, text as String) as NumberFont {
        if (field.largeNumber) {
            return NUMBER_FONT_48;
        }
        var length = text.length();
        if (length <= 3) {
            return NUMBER_FONT_26;
        }
        return length == 4 ? NUMBER_FONT_22 : NUMBER_FONT_18;
    }

    // A number font's width table, base and cap height. The renderer maps
    // the same fonts to their resources (Fonts.number).
    function numberMetrics(font as NumberFont) as FontMetrics {
        switch (font) {
            case NUMBER_FONT_26:
                return new FontMetrics(GlyphWidths.NUMBER_26, GlyphWidths.NUMBER_26_BASE,
                    GlyphWidths.NUMBER_26_CAP_HEIGHT);
            case NUMBER_FONT_22:
                return new FontMetrics(GlyphWidths.NUMBER_22, GlyphWidths.NUMBER_22_BASE,
                    GlyphWidths.NUMBER_22_CAP_HEIGHT);
            case NUMBER_FONT_18:
                return new FontMetrics(GlyphWidths.NUMBER_18, GlyphWidths.NUMBER_18_BASE,
                    GlyphWidths.NUMBER_18_CAP_HEIGHT);
        }
        return new FontMetrics(GlyphWidths.NUMBER_48, GlyphWidths.NUMBER_48_BASE,
            GlyphWidths.NUMBER_48_CAP_HEIGHT);
    }

    // The code point of a metric's icon in the icon font, null if the icon
    // font has none for it yet (heart and foot come with tickets 09-10).
    function iconOf(metric as Metric) as Number? {
        switch (metric) {
            case METRIC_BODY_BATTERY:
                return GlyphWidths.ICON_BOLT;
            case METRIC_STRESS:
                return GlyphWidths.ICON_STRESS;
        }
        return null;
    }

    // The warning color for a metric's value, null when there is no warning.
    function warningColor(metric as Metric, value as Number, theme as Theme) as Number? {
        switch (metric) {
            case METRIC_BODY_BATTERY:
                // Red below 15, orange at 15-24.
                if (value < 15) {
                    return theme.warningLevel2;
                }
                return value < 25 ? theme.warningLevel1 : null;
            case METRIC_STRESS:
                // Red above 75, orange at 51-75.
                if (value > 75) {
                    return theme.warningLevel2;
                }
                return value > 50 ? theme.warningLevel1 : null;
        }
        return null; // heart rate has no warning color; steps have a goal instead
    }

    // clamp(value, 0, 100) x 360 / 100, rounded down.
    function gaugeSweep(value as Number) as Number {
        return clamp(value, 0, 100) * 360 / 100;
    }

    // The current value of a metric, null when missing.
    function metricValue(metric as Metric, snapshot as Snapshot) as Number? {
        switch (metric) {
            case METRIC_BODY_BATTERY:
                return snapshot.bodyBattery;
            case METRIC_STRESS:
                return snapshot.stress;
            case METRIC_STEPS:
                return snapshot.steps;
        }
        return null; // heart rate comes with ticket 09
    }

    // The goal of a goal metric (one whose goal is read from the watch),
    // null when missing or when the metric has no goal. Only a goal metric
    // goes on the bezel ring (Layout.BEZEL_METRIC).
    function goalOf(metric as Metric, snapshot as Snapshot) as Number? {
        return metric == METRIC_STEPS ? snapshot.stepGoal : null;
    }

    // The static layer for a theme.
    function staticLayer(theme as Theme) as StaticLayer {
        var layer = new StaticLayer();
        layer.backgroundColor = theme.background;
        layer.wellColor = theme.ink;
        layer.timeBandColor = theme.accent;
        layer.bezelTrack = arc(Layout.CENTER_X, Layout.CENTER_Y, Layout.BEZEL_RADIUS,
            Layout.BEZEL_PEN, 0, 360, theme.bezelTrack);

        var half = Layout.BATTERY_WELL_HALF;
        layer.batteryWell = arc(Layout.CENTER_X, Layout.CENTER_Y, Layout.BATTERY_RADIUS,
            Layout.BATTERY_WELL_PEN, -half, 2 * half, theme.ink);
        layer.batteryCaps = [
            batteryCap(-half, theme.ink),
            batteryCap(half, theme.ink)
        ] as Array<Circle>;

        var track = new Array<Arc>[Layout.BATTERY_SEGMENTS];
        for (var i = 0; i < Layout.BATTERY_SEGMENTS; i++) {
            track[i] = batterySegment(i, theme.gaugeTrack);
        }
        layer.batteryTrack = track;

        // Every metric in a round field so far is a gauge, so every round
        // field has a full-circle track.
        var fields = [Layout.leftField(), Layout.centerField()] as Array<RoundField>;
        var wells = new Array<Circle>[fields.size()];
        var tracks = new Array<Arc>[fields.size()];
        for (var i = 0; i < fields.size(); i++) {
            var field = fields[i];
            wells[i] = new Circle(field.x, field.y, field.radius + Layout.WELL, theme.ink);
            tracks[i] = arc(field.x, field.y, field.gaugeRadius, field.gaugePen, 0, 360,
                theme.gaugeTrack);
        }
        layer.fieldWells = wells;
        layer.gaugeTracks = tracks;
        return layer;
    }

    // lit = (battery + 9) / 10, clamped to 0-10; missing lights none.
    function batteryLit(battery as Number?, theme as Theme) as Array<Arc> {
        var lit = 0;
        var color = theme.accent;
        if (battery != null) {
            lit = clamp((battery + 9) / 10, 0, Layout.BATTERY_SEGMENTS);
            color = batteryColor(battery, theme);
        }
        var segments = new Array<Arc>[lit];
        for (var i = 0; i < lit; i++) {
            segments[i] = batterySegment(i, color);
        }
        return segments;
    }

    // min(value, goal) x 360 / goal, multiplication first and rounded down,
    // so the ring closes only when the goal is reached.
    function bezelSweep(value as Number?, goal as Number?) as Number {
        // The null checks repeat hasGoalProgress for the type checker.
        if (value == null || goal == null || !hasGoalProgress(value, goal)) {
            return 0;
        }
        return (value < goal ? value : goal) * 360 / goal;
    }

    // The black notches across the bezel ring at 3, 6 and 9 o'clock (one per
    // design angle in Layout.BEZEL_NOTCHES), from the inner to the outer
    // radius. Like the static layer they depend only on the theme, so the
    // renderer gets them once; unlike it they are drawn on every update,
    // over the progress (they are not in the buffer).
    function bezelNotches(theme as Theme) as Array<Line> {
        var angles = Layout.BEZEL_NOTCHES;
        var notches = new Array<Line>[angles.size()];
        for (var i = 0; i < angles.size(); i++) {
            var inner = pointAt(angles[i], Layout.BEZEL_NOTCH_INNER);
            var outer = pointAt(angles[i], Layout.BEZEL_NOTCH_OUTER);
            notches[i] = new Line(inner[0], inner[1], outer[0], outer[1],
                Layout.BEZEL_NOTCH_PEN, theme.ink);
        }
        return notches;
    }

    // goal > 0, value known and value >= goal.
    function goalReached(value as Number?, goal as Number?) as Boolean {
        return value != null && goal != null && hasGoalProgress(value, goal) && value >= goal;
    }

    // Progress of a goal metric can be shown: the goal is above 0 and the
    // value is known (0 included; a negative value, such as a negative step
    // count, is no reading).
    function hasGoalProgress(value as Number?, goal as Number?) as Boolean {
        return value != null && goal != null && goal > 0 && value >= 0;
    }

    // Red at 10% or less, orange at 20% or less, otherwise the accent.
    function batteryColor(battery as Number, theme as Theme) as Number {
        if (battery <= 10) {
            return theme.warningLevel2;
        }
        return battery <= 20 ? theme.warningLevel1 : theme.accent;
    }

    // Battery segment i (0 = leftmost) in the given color.
    function batterySegment(i as Number, color as Number) as Arc {
        return arc(Layout.CENTER_X, Layout.CENTER_Y, Layout.BATTERY_RADIUS, Layout.BATTERY_PEN,
            Layout.BATTERY_FIRST + i * Layout.BATTERY_STEP, Layout.BATTERY_SEGMENT, color);
    }

    // A round cap of the battery well, centered on the well at
    // `designDegrees`.
    function batteryCap(designDegrees as Number, color as Number) as Circle {
        return circleAt(designDegrees, Layout.BATTERY_RADIUS, Layout.BATTERY_WELL_PEN / 2,
            color);
    }

    // A filled circle whose center sits `distance` from the face center at
    // `designDegrees`.
    function circleAt(designDegrees as Number, distance as Number, radius as Number,
            color as Number) as Circle {
        var center = pointAt(designDegrees, distance);
        return new Circle(center[0], center[1], radius, color);
    }

    // The point `distance` from the face center at `designDegrees`, rounded
    // to whole pixels: [x, y].
    function pointAt(designDegrees as Number, distance as Number) as Array<Number> {
        var angle = Math.toRadians(designDegrees);
        return [
            Math.round(Layout.CENTER_X + distance * Math.sin(angle)).toNumber(),
            Math.round(Layout.CENTER_Y - distance * Math.cos(angle)).toNumber()
        ] as Array<Number>;
    }

    // An arc from design degrees (0 = 12 o'clock, clockwise positive) to the
    // arc contract. `sweep` runs clockwise from `designStart`, 0-360.
    function arc(x as Number, y as Number, radius as Number, pen as Number,
            designStart as Number, sweep as Number, color as Number) as Arc {
        return new Arc(x, y, radius, pen, toCiq(designStart), toCiq(designStart + sweep),
            sweep, color);
    }

    // Design degrees to Connect IQ degrees: (90 - design) mod 360, in 0-359.
    // Monkey C's % keeps the sign of the dividend, hence the correction.
    function toCiq(design as Number) as Number {
        var ciq = (90 - design) % 360;
        return ciq < 0 ? ciq + 360 : ciq;
    }

    function clamp(value as Number, low as Number, high as Number) as Number {
        return value < low ? low : (value > high ? high : value);
    }

    // The folded weekday, a space and the day of month without a leading zero.
    // A name that is missing, empty or cannot be folded, or that would make
    // the pill wider than the time band (Q33), falls back to the English
    // abbreviation of the weekday number.
    function dateText(snapshot as Snapshot) as String {
        var day = " " + snapshot.day;
        var name = foldWeekday(snapshot.weekdayName);
        if (name != null) {
            name = shortenVietnamese(name);
        }
        if (name != null && name.length() > 0) {
            var text = name + day;
            if (datePillWidth(textWidth(text, GlyphWidths.DATE)) <= Layout.DATE_PILL_MAX_WIDTH) {
                return text;
            }
        }
        return ENGLISH_WEEKDAYS[snapshot.weekdayNumber - 1] + day;
    }

    // Vietnamese weekdays in their usual short form (Q21): "THU 2" ... "THU 7"
    // (folded from "Thứ 2" ... "Thứ 7") become "T2" ... "T7", and "CHU NHAT"
    // (Sunday) becomes "CN". Every other name is returned as it is.
    function shortenVietnamese(name as String) as String {
        if (name.equals("CHU NHAT")) {
            return "CN";
        }
        if (name.length() == 5 && "THU ".equals(name.substring(0, 4))) {
            var digit = name.toCharArray()[4];
            if (digit >= '2' && digit <= '7') {
                return "T" + digit;
            }
        }
        return name;
    }

    // max(minimum, text width + 2 x pad), where the pad gives "THU 12"
    // exactly the minimum width (Q23). The font generator derives the pad
    // from the same 96 px (its FONTS entry for the date).
    function datePillWidth(textWidth as Number) as Number {
        var width = textWidth + 2 * GlyphWidths.DATE_PAD;
        return width > Layout.DATE_PILL_MIN_WIDTH ? width : Layout.DATE_PILL_MIN_WIDTH;
    }

    // The weekday folded code point by code point to A-Z, keeping spaces and
    // the digits 0-9 and dropping combining marks. Null if any other
    // character remains.
    function foldWeekday(name as String?) as String? {
        if (name == null) {
            return null;
        }
        var folded = "";
        var chars = name.toCharArray();
        for (var i = 0; i < chars.size(); i++) {
            var code = chars[i].toNumber();
            if (isCombiningMark(code)) {
                continue; // its base letter came before it
            }
            var c = foldChar(code);
            if (c == null) {
                return null;
            }
            folded += c;
        }
        return folded;
    }

    // The combining diacritical mark blocks: the main one, its extended and
    // supplement blocks, and the marks for symbols.
    function isCombiningMark(c as Number) as Boolean {
        return (c >= 0x0300 && c <= 0x036F) || (c >= 0x1AB0 && c <= 0x1AFF)
            || (c >= 0x1DC0 && c <= 0x1DFF) || (c >= 0x20D0 && c <= 0x20FF);
    }

    // One code point folded: its base letter in A-Z, itself for a space or
    // digit, or null if the date font cannot show it.
    function foldChar(c as Number) as Char? {
        if ((c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == ' ') {
            return c.toChar();
        }
        if (c >= 'a' && c <= 'z') {
            return (c - 32).toChar();
        }
        if (c >= 0x00C0 && c <= 0x00FF) {
            return baseFromTable(LATIN_1_BASE, c - 0x00C0);
        }
        if (c >= 0x0100 && c <= 0x017F) {
            return baseFromTable(LATIN_EXTENDED_A_BASE, c - 0x0100);
        }
        if (c == 0x01A0 || c == 0x01A1) {
            return 'O'; // Vietnamese O with horn
        }
        if (c == 0x01AF || c == 0x01B0) {
            return 'U'; // Vietnamese U with horn
        }
        if (c >= 0x0218 && c <= 0x021B) {
            return c < 0x021A ? 'S' : 'T'; // Romanian S and T with comma below
        }
        if (c >= 0x1EA0 && c <= 0x1EF9) {
            return vietnameseBase(c - 0x1EA0);
        }
        return null;
    }

    // The base letter at `offset` in a fold table, null for "?".
    function baseFromTable(table as String, offset as Number) as Char? {
        var c = table.toCharArray()[offset];
        return c == '?' ? null : c;
    }

    // Latin Extended Additional U+1EA0-U+1EF9, the Vietnamese letters with
    // tone marks, upper and lower case alternating: 24 A, 16 E, 4 I, 24 O,
    // 14 U and 8 Y.
    function vietnameseBase(offset as Number) as Char {
        if (offset < 24) {
            return 'A';
        }
        if (offset < 40) {
            return 'E';
        }
        if (offset < 44) {
            return 'I';
        }
        if (offset < 68) {
            return 'O';
        }
        return offset < 82 ? 'U' : 'Y';
    }

    // Always 24 h with a leading zero, for example "08:42" (Q22).
    function formatTime(hour as Number, minute as Number) as String {
        return hour.format("%02d") + ":" + minute.format("%02d");
    }

    // Width of text drawn in a generated font: the sum of its glyphs'
    // xadvance values. A glyph missing from the table counts as 0.
    function textWidth(text as String, widths as Dictionary<Char, Number>) as Number {
        var total = 0;
        var chars = text.toCharArray();
        for (var i = 0; i < chars.size(); i++) {
            var w = widths[chars[i]];
            if (w != null) {
                total += w;
            }
        }
        return total;
    }
}
