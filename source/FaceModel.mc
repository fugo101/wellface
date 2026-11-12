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
        var sweep = bezelSweep(snapshot.steps, snapshot.stepGoal);
        frame.bezelProgress = arc(Layout.CENTER_X, Layout.CENTER_Y, Layout.BEZEL_RADIUS,
            Layout.BEZEL_PEN, 0, sweep, theme.accent);
        frame.stepGoalReached = goalReached(snapshot.steps, snapshot.stepGoal);
        if (hasStepProgress(snapshot.steps, snapshot.stepGoal)) {
            frame.bezelHead = circleAt(sweep, Layout.BEZEL_RADIUS, Layout.BEZEL_HEAD_RADIUS,
                theme.text);
        }
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

    // min(steps, goal) x 360 / goal, multiplication first and rounded down,
    // so the ring closes only when the goal is reached.
    function bezelSweep(steps as Number?, goal as Number?) as Number {
        // The null checks repeat hasStepProgress for the type checker.
        if (steps == null || goal == null || !hasStepProgress(steps, goal)) {
            return 0;
        }
        return (steps < goal ? steps : goal) * 360 / goal;
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

    // goal > 0, steps known and steps >= goal.
    function goalReached(steps as Number?, goal as Number?) as Boolean {
        return steps != null && goal != null && hasStepProgress(steps, goal) && steps >= goal;
    }

    // Progress toward the goal can be shown: the goal is above 0 and the
    // steps are known (0 steps included; a negative count is no reading).
    function hasStepProgress(steps as Number?, goal as Number?) as Boolean {
        return steps != null && goal != null && goal > 0 && steps >= 0;
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
