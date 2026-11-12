import Toybox.Lang;
import Toybox.Math;

// The data a frame is computed from. Built by the data reader from the
// watch's clock and sensors; FaceModel never reads them itself.
class Snapshot {
    // Clock part, read on every update that is not OFF.
    // 0-23, whatever the watch's 12/24 h setting is (Q22).
    public var hour as Number;
    public var minute as Number;

    // Sensor part, read once a minute in high power. Null means missing.
    // Watch battery in percent, already rounded and clamped to 0-100.
    public var battery as Number? = null;

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
    // The lit battery segments only, leftmost first. The static layer holds
    // all ten unlit ones underneath.
    public var batteryLit as Array<Arc> = [] as Array<Arc>;

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
    function compute(snapshot as Snapshot, theme as Theme) as Frame {
        var frame = new Frame();
        frame.time = formatTime(snapshot.hour, snapshot.minute);
        frame.timeWidth = textWidth(frame.time, GlyphWidths.TIME);
        frame.timeX = Layout.TIME_CENTER_X - frame.timeWidth / 2;
        frame.timeY = Layout.TIME_BASELINE_Y - GlyphWidths.TIME_BASE;
        frame.timeColor = theme.ink;
        frame.batteryLit = batteryLit(snapshot.battery, theme);
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
        var angle = Math.toRadians(designDegrees);
        var r = Layout.BATTERY_RADIUS;
        return new Circle(
            Math.round(Layout.CENTER_X + r * Math.sin(angle)).toNumber(),
            Math.round(Layout.CENTER_Y - r * Math.cos(angle)).toNumber(),
            Layout.BATTERY_WELL_PEN / 2, color);
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
