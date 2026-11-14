import Toybox.Lang;
import Toybox.Math;

// The data a frame is computed from. Built by the data reader from the
// watch's clock and sensors; FaceModel never reads them itself.
class Snapshot {
    // Clock part, read on every update that is not OFF.
    // 0-23, whatever the watch's 12/24 h setting is (Q22).
    public var hour as Number;
    public var minute as Number;
    // 0-59. Not read from the clock or drawn yet (seconds, Q41); the capture
    // face sets it for its scenarios.
    public var second as Number = 0;
    // Day of month, 1-31, and month, 1-12.
    public var day as Number = 1;
    public var month as Number = 1;
    // Weekday number from FORMAT_SHORT: 1 = Sunday ... 7 = Saturday.
    public var weekdayNumber as Number = 1;
    // The localized weekday name from FORMAT_MEDIUM, as the watch returns it.
    public var weekdayName as String? = null;

    // Sensor part, read in high power only. Null means missing.
    // Watch battery in percent, already rounded and clamped to 0-100.
    public var battery as Number? = null;
    // The lower bounds of heart-rate zones 1-5 in bpm (the first five
    // HR_ZONE_SPORT_GENERIC thresholds), null when unreadable.
    public var heartRateZones as Array<Number>? = null;
    // Each metric's value and, for a goal metric, its goal (the step goal is
    // the watch's own auto goal, never entered by hand), indexed by metric.
    // Only the metrics the face config shows are read, each at its cadence
    // (FaceModel.readPlan); a metric no longer shown keeps its last value.
    // The data reader keeps only whole numbers; FaceModel treats a negative
    // one as missing (Metrics.reading).
    private var _values as Array<Number?>;
    private var _goals as Array<Number?>;

    function initialize(hour as Number, minute as Number) {
        self.hour = hour;
        self.minute = minute;
        _values = new Array<Number?>[Metrics.ALL.size()];
        _goals = new Array<Number?>[Metrics.ALL.size()];
    }

    function value(metric as Metric) as Number? {
        return _values[metric];
    }

    function setValue(metric as Metric, value as Number?) as Void {
        _values[metric] = value;
    }

    function goal(metric as Metric) as Number? {
        return _goals[metric];
    }

    function setGoal(metric as Metric, goal as Number?) as Void {
        _goals[metric] = goal;
    }
}

// What to draw on top of the static layer: every string, color and arc the
// renderer needs. FaceModel fills in every field; the defaults only exist to
// satisfy the type checker. FaceModel.update changes a frame in place, part
// by part, so a frame is only made when there is none yet (at start and when
// a face config is applied). Its placeholder objects are then allocated and
// overwritten at once, but only then, never on a per-second or per-minute
// update.
class Frame {
    public var time as String = "";
    // Width of the time in the time font, from its catalog entry.
    public var timeWidth as Number = 0;
    // Top-left corner to draw the time from (left-justified, line top).
    public var timeX as Number = 0;
    public var timeY as Number = 0;
    public var timeColor as Number = 0;
    // The date text, for example "THU 12/11", its width (dateTextWidth) and
    // the top-left corner of the whole text (left-justified, line top),
    // centered as one group.
    public var date as String = "";
    public var dateWidth as Number = 0;
    public var dateX as Number = 0;
    public var dateY as Number = 0;
    // The date is drawn as two runs on dateY (stories 35, 36): the weekday
    // from dateX in the accent, then the day/month from dayMonthX, after the
    // weekday and the space, in the text color.
    public var weekday as String = "";
    public var weekdayColor as Number = 0;
    public var dayMonth as String = "";
    public var dayMonthX as Number = 0;
    public var dayMonthColor as Number = 0;
    // The black pill behind the date; its width follows the text.
    public var datePill as RoundedRect = new RoundedRect(0, 0, 0, 0, 0, 0);
    // The lit battery segments only, leftmost first. The static layer holds
    // all ten unlit ones underneath.
    public var batteryLit as Array<Arc> = [] as Array<Arc>;
    // The bezel ring's goal metric's progress, over the static track. Sweep
    // 0 when there is no progress to show.
    public var bezelProgress as Arc = new Arc(0, 0, 0, 0, 0, 0, 0, 0);
    // The dot at the head of the progress, null when there is no goal to
    // show progress toward or the value is missing.
    public var bezelHead as Circle? = null;
    // The bottom field's goal reached: the goal is above 0, the value is
    // known and at least the goal. The bottom field switches style on it.
    public var bottomGoalReached as Boolean = false;
    // The bottom field's content.
    public var bottomField as BottomFieldFrame =
        new BottomFieldFrame(new RoundedRect(0, 0, 0, 0, 0, 0));
    // The round fields' content.
    public var leftField as FieldFrame = new FieldFrame([] as Array<Arc>);
    public var centerField as FieldFrame = new FieldFrame([] as Array<Arc>);
    public var rightField as FieldFrame = new FieldFrame([] as Array<Arc>);

    function initialize() {
    }
}

// The Always On frame (Q12, Q13, Q28): only the time, filled, and the date,
// as filled text inside an outlined pill, all in the AOD color and moved by
// the burn-in offset of the current minute. Everything else stays black.
// FaceModel fills in every field; the defaults only exist to satisfy the
// type checker.
class AodFrame {
    // The time in the time font, drawn from its top-left corner
    // (left-justified, line top).
    public var time as String = "";
    public var timeX as Number = 0;
    public var timeY as Number = 0;
    public var timeColor as Number = 0;
    // The date text, filled, from its top-left corner.
    public var date as String = "";
    public var dateX as Number = 0;
    public var dateY as Number = 0;
    public var dateColor as Number = 0;
    // The pill around the date as an outline: datePill filled in the AOD
    // color, then datePillInner filled black over it, so the outline is
    // exactly the gap between them.
    public var datePill as RoundedRect = new RoundedRect(0, 0, 0, 0, 0, 0);
    public var datePillInner as RoundedRect = new RoundedRect(0, 0, 0, 0, 0, 0);
    // The burn-in offset this frame is moved by, in px.
    public var offsetX as Number = 0;
    public var offsetY as Number = 0;

    function initialize() {
    }
}

// What a hold at a touch point opens: the field held and the metric it
// shows. The metric picks the Garmin page, not the field (Q29).
class LongPressTarget {
    public var field as Field;
    public var metric as Metric;

    function initialize(field as Field, metric as Metric) {
        self.field = field;
        self.metric = metric;
    }
}

// What the bottom field draws: its pill (which is its own well), the goal
// metric's icon, its number and "/ goal", each placed from the font catalog.
class BottomFieldFrame {
    public var pill as RoundedRect;
    // The metric's icon, "" when hidden to make room.
    public var icon as String = "";
    public var iconX as Number = 0;
    public var iconY as Number = 0;
    public var iconColor as Number = 0;
    // The value in the metric's number format, or "--". Drawn from its
    // top-left corner (left-justified, line top), like every text.
    public var number as String = "";
    public var numberFont as FontId = FONT_NUMBER_22;
    public var numberWidth as Number = 0;
    public var numberX as Number = 0;
    public var numberY as Number = 0;
    public var numberColor as Number = 0;
    // "/ " and the goal, in the goal font; "" when there is no goal to show.
    public var goal as String = "";
    public var goalX as Number = 0;
    public var goalY as Number = 0;
    public var goalColor as Number = 0;

    function initialize(pill as RoundedRect) {
        self.pill = pill;
    }
}

// What a field draws over its static well and track: the lit arcs, the icon
// and the number. Which arcs, colors and strings depends on the metric shown.
class FieldFrame {
    // Drawn over the track. A gauge has one arc, or none when the value is
    // missing or 0; zone segments have one arc per zone reached.
    public var arcs as Array<Arc>;
    // The arcs' round caps (FaceModel.roundCaps), drawn over them.
    public var caps as Array<Circle> = [] as Array<Circle>;
    // The white dot at the end of the gauge, over its cap; null when the
    // metric has none or its value is 0 or missing.
    public var dot as Circle? = null;
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
    public var numberFont as FontId = FONT_NUMBER_48;
    public var numberWidth as Number = 0;
    public var numberX as Number = 0;
    public var numberY as Number = 0;

    function initialize(arcs as Array<Arc>) {
        self.arcs = arcs;
    }
}

// The parts of the face that depend only on the face config, drawn once into
// a buffer by the renderer, back to front: bezel track, background disc, well
// rims, battery well and track, time band well and band, field wells,
// tracks and track caps. They depend on both the theme and the field
// mapping: the metric each round field shows decides its track. So the whole
// layer is rebuilt whenever a face config is applied
// (WellfaceView.applyConfig), never for a theme change alone. The disc's
// geometry is in Layout.
class StaticLayer {
    public var backgroundColor as Number = 0;
    // The well rims (Q39): around the time band's well, around each round
    // field's well (same order as fieldWells) and around the bottom field's
    // pill, which is its own well and is drawn over the rim on every update.
    public var timeBandRim as RoundedRect = new RoundedRect(0, 0, 0, 0, 0, 0);
    public var fieldRims as Array<Circle> = [] as Array<Circle>;
    public var bottomFieldRim as RoundedRect = new RoundedRect(0, 0, 0, 0, 0, 0);
    // The time band's black well and the band itself.
    public var timeBandWell as RoundedRect = new RoundedRect(0, 0, 0, 0, 0, 0);
    public var timeBand as RoundedRect = new RoundedRect(0, 0, 0, 0, 0, 0);
    public var bezelTrack as Arc = new Arc(0, 0, 0, 0, 0, 0, 0, 0);
    public var batteryWell as Arc = new Arc(0, 0, 0, 0, 0, 0, 0, 0);
    // The round ends of the battery well, left first.
    public var batteryCaps as Array<Circle> = [] as Array<Circle>;
    // The ten battery segments, all unlit, leftmost first.
    public var batteryTrack as Array<Arc> = [] as Array<Arc>;
    // The black wells of the round fields, and the tracks of their gauges.
    public var fieldWells as Array<Circle> = [] as Array<Circle>;
    // The track under each field's lit arcs: a full circle under a gauge,
    // the five unlit segments under zone segments.
    public var fieldTracks as Array<Arc> = [] as Array<Arc>;
    // The tracks' round caps (the unlit segments'; a full circle has none).
    public var fieldTrackCaps as Array<Circle> = [] as Array<Circle>;

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
    // Always On: black, the pixels left off. A platform rule, not a theme
    // color.
    const AOD_BLACK = 0x000000;
    // Indices into dateParts.
    const DATE_WEEKDAY = 0;
    const DATE_DAY_MONTH = 1;
    const DATE_TEXT = 2;

    // The frame part of each field, indexed by field.
    const FIELD_PARTS = [PART_LEFT, PART_CENTER, PART_RIGHT, PART_BOTTOM, PART_BEZEL_RING]
        as Array<Number>;

    const LATIN_EXTENDED_A_BASE =
        "AAAAAACCCCCCCCDDDDEEEEEEEEEEGGGGGGGGHHHHIIIIIIIIII??JJKK?LLLLLLLLLL" +
        "NNNNNN?NNOOOOOO??RRRRRRSSSSSSSSTTTTTTUUUUUUUUUUUUWWYYYZZZZZZS";

    // Every part of the high-power frame (FramePart bits, all but the AOD
    // frame).
    const HIGH_POWER_PARTS = PART_LEFT | PART_CENTER | PART_RIGHT | PART_BOTTOM
        | PART_BEZEL_RING | PART_TIME | PART_DATE | PART_BATTERY;

    // The high-power frame for a snapshot and a resolved face config, all of
    // it computed.
    function compute(snapshot as Snapshot, config as ResolvedFaceConfig) as Frame {
        return update(null, snapshot, config, CHANGE_ALL);
    }

    // The high-power frame for a snapshot and a resolved face config,
    // recomputing only the parts `changes` (ChangeKind bits) invalidate.
    // `previous` is updated in place and returned; without one, a new frame
    // is computed in full. The result equals compute(snapshot, config)
    // provided `changes` covers every change since `previous` was computed
    // for the same face config (a new face config needs a null previous).
    function update(previous as Frame?, snapshot as Snapshot, config as ResolvedFaceConfig,
            changes as Number) as Frame {
        var frame = previous;
        var parts = HIGH_POWER_PARTS;
        if (frame == null) {
            frame = new Frame();
        } else {
            parts = invalidated(changes, config);
        }
        var theme = config.theme;
        if ((parts & PART_TIME) != 0) {
            frame.time = formatTime(snapshot.hour, snapshot.minute);
            var timeFont = FontCatalog.entry(FONT_TIME);
            frame.timeWidth = textWidth(frame.time, timeFont);
            frame.timeX = Layout.TIME_CENTER_X - frame.timeWidth / 2;
            frame.timeY = Layout.TIME_BASELINE_Y - timeFont.base;
            frame.timeColor = theme.ink;
        }
        if ((parts & PART_DATE) != 0) {
            var date = dateParts(snapshot);
            frame.weekday = date[DATE_WEEKDAY];
            frame.dayMonth = date[DATE_DAY_MONTH];
            frame.date = date[DATE_TEXT];
            frame.dateWidth = dateTextWidth(frame.date);
            frame.dateX = Layout.CENTER_X - frame.dateWidth / 2;
            // Upper case only, so the capitals are centered, as in the design.
            var dateFont = FontCatalog.entry(FONT_DATE);
            frame.dateY = digitsTop(Layout.DATE_CENTER_Y, dateFont.capHeight, dateFont.base);
            // The date font bakes its letter spacing into every advance, so
            // the weekday's and the space's advances put the day/month where
            // it is in the whole text.
            // The date font has the space (its glyph set includes it).
            frame.dayMonthX = frame.dateX + textWidth(frame.weekday, dateFont)
                + (dateFont.widths[' '] as Number);
            frame.weekdayColor = theme.accent;
            frame.dayMonthColor = theme.text;
            var pillWidth = datePillWidth(frame.dateWidth);
            frame.datePill = new RoundedRect(Layout.CENTER_X - pillWidth / 2, Layout.DATE_PILL_Y,
                pillWidth, Layout.DATE_PILL_HEIGHT, Layout.DATE_PILL_RADIUS, theme.ink);
        }
        if ((parts & PART_BATTERY) != 0) {
            frame.batteryLit = batteryLit(snapshot.battery, theme);
        }
        if ((parts & PART_BEZEL_RING) != 0) {
            // Progress of its goal metric toward the goal.
            var bezelMetric = config.metricOf(FIELD_BEZEL_RING);
            var bezelValue = metricValue(bezelMetric, snapshot);
            var bezelGoal = goalOf(bezelMetric, snapshot);
            var sweep = bezelSweep(bezelValue, bezelGoal);
            frame.bezelProgress = arc(Layout.CENTER_X, Layout.CENTER_Y, Layout.BEZEL_RADIUS,
                Layout.BEZEL_PEN, 0, sweep, theme.accent);
            frame.bezelHead = hasGoalProgress(bezelValue, bezelGoal)
                ? circleAt(sweep, Layout.BEZEL_RADIUS, Layout.BEZEL_HEAD_RADIUS, theme.text)
                : null;
        }
        if ((parts & PART_BOTTOM) != 0) {
            var bottomMetric = config.metricOf(FIELD_BOTTOM);
            var bottomValue = metricValue(bottomMetric, snapshot);
            var bottomGoal = goalOf(bottomMetric, snapshot);
            frame.bottomGoalReached = goalReached(bottomValue, bottomGoal);
            frame.bottomField = bottomField(bottomMetric, bottomValue, bottomGoal, theme);
        }
        var round = Layout.ROUND_FIELDS;
        for (var i = 0; i < round.size(); i++) {
            var field = round[i];
            if ((parts & FIELD_PARTS[field]) == 0) {
                continue;
            }
            var content = roundField(Layout.roundField(field), config.metricOf(field), snapshot,
                theme);
            if (field == FIELD_LEFT) {
                frame.leftField = content;
            } else if (field == FIELD_CENTER) {
                frame.centerField = content;
            } else {
                frame.rightField = content;
            }
        }
        return frame;
    }

    // The Always On frame for a snapshot and a resolved face config:
    // `previous` itself unless `changes` (ChangeKind bits) invalidate it
    // (only a clock change does), else a new one. A new face config needs a
    // null previous.
    function updateAod(previous as AodFrame?, snapshot as Snapshot,
            config as ResolvedFaceConfig, changes as Number) as AodFrame {
        if (previous != null && (invalidated(changes, config) & PART_AOD) == 0) {
            return previous;
        }
        return computeAod(snapshot, config);
    }

    // The Always On frame for the snapshot's clock. Sensors are not used, and
    // of the face config only the theme.
    function computeAod(snapshot as Snapshot, config as ResolvedFaceConfig) as AodFrame {
        var frame = new AodFrame();
        var offsets = Layout.AOD_OFFSETS;
        var offset = offsets[snapshot.minute % offsets.size()];
        frame.offsetX = offset[0];
        frame.offsetY = offset[1];
        frame.time = formatTime(snapshot.hour, snapshot.minute);
        var timeFont = FontCatalog.entry(FONT_TIME);
        frame.timeX = Layout.TIME_CENTER_X - textWidth(frame.time, timeFont) / 2 + frame.offsetX;
        frame.timeY = Layout.TIME_BASELINE_Y - timeFont.base + frame.offsetY;
        frame.date = dateText(snapshot);
        var dateWidth = dateTextWidth(frame.date);
        frame.dateX = Layout.CENTER_X - dateWidth / 2 + frame.offsetX;
        var dateFont = FontCatalog.entry(FONT_DATE);
        frame.dateY = digitsTop(Layout.DATE_CENTER_Y, dateFont.capHeight, dateFont.base)
            + frame.offsetY;
        var color = config.theme.aodColor;
        frame.timeColor = color;
        frame.dateColor = color;
        // The outline's outer edge is the normal pill's edge.
        var pillWidth = datePillWidth(dateWidth);
        var pill = new RoundedRect(Layout.CENTER_X - pillWidth / 2 + frame.offsetX,
            Layout.DATE_PILL_Y + frame.offsetY, pillWidth, Layout.DATE_PILL_HEIGHT,
            Layout.DATE_PILL_RADIUS, color);
        frame.datePill = pill;
        frame.datePillInner = inset(pill, Layout.AOD_PILL_OUTLINE, AOD_BLACK);
        return frame;
    }

    // The face config to draw: the named theme, or the default theme (Mint,
    // Q9) for an unknown name, whatever theme the built-in config names, and
    // in each field the metric asked for if the field
    // accepts it, else that field's default metric (Q40). Never an empty
    // field; duplicates are kept.
    function resolve(config as FaceConfig) as ResolvedFaceConfig {
        var defaults = FaceConfigs.defaultConfig();
        var theme = Themes.named(config.themeName);
        if (theme == null) {
            theme = Themes.mint();
        }
        var fields = Layout.FIELDS;
        var metrics = new Array<Metric>[fields.size()];
        for (var i = 0; i < fields.size(); i++) {
            var field = fields[i];
            var metric = config.metricOf(field);
            metrics[i] = accepts(field, metric) ? metric : defaults.metricOf(field);
        }
        return new ResolvedFaceConfig(theme, metrics);
    }

    // What the data reader reads for a resolved face config: each metric
    // shown in any field, once, at its own cadence (Metrics), and the zones
    // when a field draws zone segments. High power only; the battery is
    // always read (ReadPlan).
    function readPlan(config as ResolvedFaceConfig) as ReadPlan {
        var everySecond = [] as Array<Metric>;
        var everyMinute = [] as Array<Metric>;
        var zones = false;
        var all = Metrics.ALL;
        for (var i = 0; i < all.size(); i++) {
            var metric = all[i];
            if (!shows(config, metric)) {
                continue;
            }
            if (Metrics.readsEverySecond(metric)) {
                everySecond.add(metric);
            } else {
                everyMinute.add(metric);
            }
            zones = zones || Metrics.needsZones(metric);
        }
        return new ReadPlan(everySecond, everyMinute, zones);
    }

    // The frame parts a set of change kinds makes stale (FramePart bits).
    // The clock: the time, the date and the AOD frame. The minute data: the
    // battery bar, the bezel ring, the bottom field and every other field
    // whose metric is read once a minute or draws zone segments (the zones
    // are minute data). The per-second metrics: only the fields, of any
    // kind, showing one. Neither minute data nor per-second metrics touch
    // the AOD frame.
    function invalidated(changes as Number, config as ResolvedFaceConfig) as Number {
        var parts = 0;
        if ((changes & CHANGE_CLOCK) != 0) {
            parts |= PART_TIME | PART_DATE | PART_AOD;
        }
        var minuteData = (changes & CHANGE_MINUTE_DATA) != 0;
        var perSecond = (changes & CHANGE_PER_SECOND) != 0;
        if (minuteData) {
            parts |= PART_BATTERY | PART_BEZEL_RING | PART_BOTTOM;
        }
        if (minuteData || perSecond) {
            var fields = Layout.FIELDS;
            for (var i = 0; i < fields.size(); i++) {
                var metric = config.metricOf(fields[i]);
                var everySecond = Metrics.readsEverySecond(metric);
                if ((perSecond && everySecond)
                        || (minuteData && (!everySecond || Metrics.needsZones(metric)))) {
                    parts |= FIELD_PARTS[i];
                }
            }
        }
        return parts;
    }

    // Whether any field of the config shows the metric.
    function shows(config as ResolvedFaceConfig, metric as Metric) as Boolean {
        var fields = Layout.FIELDS;
        for (var i = 0; i < fields.size(); i++) {
            if (config.metricOf(fields[i]) == metric) {
                return true;
            }
        }
        return false;
    }

    // The metrics a field can show, in metric order (for a settings menu).
    function acceptedMetrics(field as Field) as Array<Metric> {
        var accepted = [] as Array<Metric>;
        var all = Metrics.ALL;
        for (var i = 0; i < all.size(); i++) {
            if (accepts(field, all[i])) {
                accepted.add(all[i]);
            }
        }
        return accepted;
    }

    // Whether a field can show a metric: its field kind accepts the metric's
    // drawing style (Q40).
    function accepts(field as Field, metric as Metric) as Boolean {
        return FieldKinds.accepts(FieldKinds.kindOf(field), Metrics.entry(metric).style);
    }

    // The long-press target at a touch point, null on a miss. The metric
    // shown in the field held picks the page.
    function longPressTarget(x as Number, y as Number, config as ResolvedFaceConfig)
            as LongPressTarget? {
        var field = fieldAt(x, y);
        return field != null ? new LongPressTarget(field, config.metricOf(field)) : null;
    }

    // The field at a touch point, null on a miss.
    function fieldAt(x as Number, y as Number) as Field? {
        var round = Layout.ROUND_FIELDS;
        for (var i = 0; i < round.size(); i++) {
            if (insideWell(Layout.roundField(round[i]), x, y)) {
                return round[i];
            }
        }
        // The bottom field's pill is its own well, so it is not padded.
        if (insideRoundedRect(x, y, Layout.BOTTOM_X, Layout.BOTTOM_Y, Layout.BOTTOM_W,
                Layout.BOTTOM_H, Layout.BOTTOM_RADIUS)) {
            return FIELD_BOTTOM;
        }
        // The bezel ring: outside the background disc, on the screen.
        if (!insideCircle(x, y, Layout.CENTER_X, Layout.CENTER_Y, Layout.DISC_RADIUS)
                && insideCircle(x, y, Layout.CENTER_X, Layout.CENTER_Y, Layout.SCREEN_RADIUS)) {
            return FIELD_BEZEL_RING;
        }
        return null;
    }

    // Inside a rounded rectangle, its edge included: within `radius` of the
    // rectangle shrunk by `radius` on every side.
    function insideRoundedRect(x as Number, y as Number, left as Number, top as Number,
            width as Number, height as Number, radius as Number) as Boolean {
        var nearestX = clamp(x, left + radius, left + width - radius);
        var nearestY = clamp(y, top + radius, top + height - radius);
        return insideCircle(x, y, nearestX, nearestY, radius);
    }

    // Inside a round field's well (the circle of radius + Layout.WELL),
    // its edge included.
    function insideWell(field as RoundField, x as Number, y as Number) as Boolean {
        return insideCircle(x, y, field.x, field.y, field.radius + Layout.WELL);
    }

    function insideCircle(x as Number, y as Number, cx as Number, cy as Number,
            radius as Number) as Boolean {
        var dx = x - cx;
        var dy = y - cy;
        return dx * dx + dy * dy <= radius * radius;
    }

    // The bottom field for a goal metric's value and goal, both already
    // through the invalid-value rule (Q24, Q25, Q34).
    // Goal not reached: the metric's icon, the number right-aligned and
    // "/ goal" left-aligned at their anchors, if that fits; else the same
    // with the number at 18 px; else the icon hidden and number + gap +
    // "/ goal" centered on the face; else "/ goal" dropped too. Goal reached:
    // the accent pill, and the icon and number (22 px, or 18 if that does
    // not fit) centered as a group in ink, without "/ goal".
    function bottomField(metric as Metric, value as Number?, goal as Number?, theme as Theme)
            as BottomFieldFrame {
        var reached = goalReached(value, goal);
        var content = new BottomFieldFrame(new RoundedRect(Layout.BOTTOM_X, Layout.BOTTOM_Y,
            Layout.BOTTOM_W, Layout.BOTTOM_H, Layout.BOTTOM_RADIUS,
            reached ? theme.accent : theme.ink));
        content.icon = iconText(metric);
        content.iconY = Layout.BOTTOM_ICON_Y;
        content.number = value != null ? Metrics.format(metric, value) : "--";

        if (reached) {
            content.iconColor = theme.ink;
            content.numberColor = theme.ink;
            var room = Layout.BOTTOM_GROUP_RIGHT - Layout.BOTTOM_GROUP_LEFT;
            var font = FONT_NUMBER_22;
            if (groupWidth(content.number, font) > room) {
                font = FONT_NUMBER_18;
            }
            content.iconX = Layout.CENTER_X - groupWidth(content.number, font) / 2;
            placeBottomNumber(content, font,
                content.iconX + Layout.ICON_SIZE + Layout.BOTTOM_REACHED_GAP);
            return content;
        }

        content.iconX = Layout.BOTTOM_ICON_X;
        content.iconColor = theme.secondary;
        content.numberColor = value != null ? theme.text : theme.secondary;
        var goalWidth = 0;
        if (goal != null && goal > 0) {
            content.goal = "/ " + Metrics.format(metric, goal);
            var goalFont = FontCatalog.entry(FONT_GOAL_15);
            goalWidth = textWidth(content.goal, goalFont);
            content.goalColor = theme.secondary;
            content.goalY = digitsTop(Layout.BOTTOM_GOAL_Y, goalFont.capHeight, goalFont.base);
        }

        // At the anchors, 22 px and then 18 px.
        var fonts = [FONT_NUMBER_22, FONT_NUMBER_18] as Array<FontId>;
        for (var i = 0; i < fonts.size(); i++) {
            var left = Layout.BOTTOM_NUMBER_RIGHT
                - textWidth(content.number, FontCatalog.entry(fonts[i]));
            if (left >= Layout.BOTTOM_NUMBER_MIN_LEFT && (content.goal.length() == 0
                    || Layout.BOTTOM_GOAL_LEFT + goalWidth <= Layout.BOTTOM_GOAL_MAX_RIGHT)) {
                placeBottomNumber(content, fonts[i], left);
                content.goalX = Layout.BOTTOM_GOAL_LEFT;
                return content;
            }
        }

        // Centered on the face without the icon; without "/ goal" as a
        // last resort.
        content.icon = "";
        var numberWidth = textWidth(content.number, FontCatalog.entry(FONT_NUMBER_18));
        var width = numberWidth;
        if (content.goal.length() > 0) {
            width += Layout.BOTTOM_GOAL_LEFT - Layout.BOTTOM_NUMBER_RIGHT + goalWidth;
            if (width > Layout.BOTTOM_GROUP_RIGHT - Layout.BOTTOM_GROUP_LEFT) {
                content.goal = "";
                width = numberWidth;
            }
        }
        placeBottomNumber(content, FONT_NUMBER_18, Layout.CENTER_X - width / 2);
        content.goalX = content.numberX + numberWidth + Layout.BOTTOM_GOAL_LEFT
            - Layout.BOTTOM_NUMBER_RIGHT;
        return content;
    }

    // The icon's box, the gap and the number in this font, side by side.
    function groupWidth(number as String, font as FontId) as Number {
        return Layout.ICON_SIZE + Layout.BOTTOM_REACHED_GAP
            + textWidth(number, FontCatalog.entry(font));
    }

    // The bottom field's number in `font`, starting at x `left`, its digits
    // centered on Layout.BOTTOM_NUMBER_Y.
    function placeBottomNumber(content as BottomFieldFrame, font as FontId, left as Number)
            as Void {
        var entry = FontCatalog.entry(font);
        content.numberFont = font;
        content.numberWidth = textWidth(content.number, entry);
        content.numberX = left;
        content.numberY = digitsTop(Layout.BOTTOM_NUMBER_Y, entry.capHeight, entry.base);
    }

    // The line top to draw text from so that its capitals (or digits) are
    // vertically centered on `centerY`: the baseline sits half a cap height
    // below it, and the line top `base` above the baseline.
    function digitsTop(centerY as Number, capHeight as Number, base as Number) as Number {
        return centerY + capHeight / 2 - base;
    }

    // A round field showing `metric`: its icon and number, plus lit arcs in
    // the metric's drawing style (zone segments or a gauge), at the field's
    // geometry. In warning, the icon, number and gauge take the warning
    // color.
    function roundField(field as RoundField, metric as Metric, snapshot as Snapshot,
            theme as Theme) as FieldFrame {
        var value = metricValue(metric, snapshot);
        var warning = value != null ? warningColor(metric, value, theme) : null;
        var entry = Metrics.entry(metric);
        var isGauge = entry.style == STYLE_GAUGE;
        var arcs = value == null ? [] as Array<Arc>
            : (isGauge
                ? gauge(field, value, warning != null ? warning : theme.accent)
                : litZoneSegments(field, value, snapshot.heartRateZones, theme.zones));
        var content = new FieldFrame(arcs);
        content.caps = roundCaps(arcs);
        if (isGauge && entry.gaugeEndDot && value != null && value > 0) {
            // A gauge above 0 always sweeps, so it has its arc.
            var end = arcEnd(arcs[0]);
            content.dot = new Circle(end[0], end[1], Layout.GAUGE_DOT_RADIUS, theme.text);
        }
        content.icon = iconText(metric);
        content.iconX = field.iconX;
        content.iconY = field.iconY;
        content.iconColor = theme.secondary;
        content.number = "--";
        content.numberColor = theme.secondary;
        if (value != null) {
            content.number = Metrics.format(metric, value);
            content.numberColor = theme.text;
            if (warning != null) {
                content.iconColor = warning;
                content.numberColor = warning;
            }
        }
        content.numberFont = numberFontFor(field, content.number);
        var font = FontCatalog.entry(content.numberFont);
        content.numberWidth = textWidth(content.number, font);
        content.numberX = field.x - content.numberWidth / 2;
        // Digits only, so their cap height is centered on numberY.
        content.numberY = digitsTop(field.numberY, font.capHeight, font.base);
        return content;
    }

    // A gauge: one arc from 12 o'clock, clockwise; none at 0.
    function gauge(field as RoundField, value as Number, color as Number) as Array<Arc> {
        var sweep = gaugeSweep(value);
        if (sweep == 0) {
            return [] as Array<Arc>;
        }
        return [arc(field.x, field.y, field.ringRadius, field.ringPen, 0, sweep, color)]
            as Array<Arc>;
    }

    // One lit segment per zone reached: the number of zone lower bounds at
    // or below the heart rate, each in its own zone's color (Q37). None
    // without zones.
    function litZoneSegments(field as RoundField, heartRate as Number,
            zones as Array<Number>?, colors as Array<Number>) as Array<Arc> {
        var lit = 0;
        if (zones != null && zones.size() >= Layout.ZONE_SEGMENTS) {
            for (var i = 0; i < Layout.ZONE_SEGMENTS; i++) {
                if (zones[i] <= heartRate) {
                    lit++;
                }
            }
        }
        var segments = new Array<Arc>[lit];
        for (var i = 0; i < lit; i++) {
            segments[i] = zoneSegment(field, i, colors[i]);
        }
        return segments;
    }

    // Zone segment i (zone i + 1) of a field, in the given color.
    function zoneSegment(field as RoundField, i as Number, color as Number) as Arc {
        return arc(field.x, field.y, field.ringRadius, field.ringPen,
            i * Layout.ZONE_STEP + Layout.ZONE_GAP, Layout.ZONE_SWEEP, color);
    }

    // The center field's number is always 48 px. The left and right numbers
    // shrink with more characters: <= 3 -> 26, 4 -> 22, >= 5 -> 18.
    function numberFontFor(field as RoundField, text as String) as FontId {
        if (field.largeNumber) {
            return FONT_NUMBER_48;
        }
        var length = text.length();
        if (length <= 3) {
            return FONT_NUMBER_26;
        }
        return length == 4 ? FONT_NUMBER_22 : FONT_NUMBER_18;
    }

    // A metric's icon: one glyph in the icon font.
    function iconText(metric as Metric) as String {
        return Metrics.entry(metric).icon.toChar().toString();
    }

    // The theme's color for a metric's warning level, null when there is no
    // warning.
    function warningColor(metric as Metric, value as Number, theme as Theme) as Number? {
        var level = Metrics.warningLevel(metric, value);
        if (level == 0) {
            return null;
        }
        return level == 1 ? theme.warningLevel1 : theme.warningLevel2;
    }

    // clamp(value, 0, 100) x 360 / 100, rounded down.
    function gaugeSweep(value as Number) as Number {
        return clamp(value, 0, 100) * 360 / 100;
    }

    // The current value of a metric, null when missing or invalid.
    function metricValue(metric as Metric, snapshot as Snapshot) as Number? {
        return Metrics.reading(snapshot.value(metric));
    }

    // The goal of a goal metric, null when missing, invalid or when the
    // metric has no goal.
    function goalOf(metric as Metric, snapshot as Snapshot) as Number? {
        return Metrics.isGoalMetric(metric) ? Metrics.reading(snapshot.goal(metric)) : null;
    }

    // The static layer for a resolved face config: its theme, and the metric
    // each round field shows (which decides the track).
    function staticLayer(config as ResolvedFaceConfig) as StaticLayer {
        var theme = config.theme;
        var layer = new StaticLayer();
        layer.backgroundColor = theme.background;
        var band = new RoundedRect(Layout.BAND_X, Layout.BAND_Y, Layout.BAND_W, Layout.BAND_H,
            Layout.BAND_RADIUS, theme.accent);
        layer.timeBand = band;
        layer.timeBandWell = inset(band, -Layout.WELL, theme.ink);
        layer.timeBandRim = inset(band, -Layout.WELL - Layout.WELL_RIM, theme.wellRim);
        layer.bottomFieldRim = inset(new RoundedRect(Layout.BOTTOM_X, Layout.BOTTOM_Y,
            Layout.BOTTOM_W, Layout.BOTTOM_H, Layout.BOTTOM_RADIUS, theme.ink),
            -Layout.WELL_RIM, theme.wellRim);
        layer.bezelTrack = arc(Layout.CENTER_X, Layout.CENTER_Y, Layout.BEZEL_RADIUS,
            Layout.BEZEL_PEN, 0, 360, theme.tickUnlit);

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

        layer.fieldRims = [] as Array<Circle>;
        layer.fieldWells = [] as Array<Circle>;
        layer.fieldTracks = [] as Array<Arc>;
        var round = Layout.ROUND_FIELDS;
        for (var i = 0; i < round.size(); i++) {
            addRoundField(layer, Layout.roundField(round[i]), config.metricOf(round[i]), theme);
        }
        layer.fieldTrackCaps = roundCaps(layer.fieldTracks);
        return layer;
    }

    // A round field's well rim and well, and the track its metric's ring is
    // drawn over.
    function addRoundField(layer as StaticLayer, field as RoundField, metric as Metric,
            theme as Theme) as Void {
        var well = field.radius + Layout.WELL;
        layer.fieldRims.add(new Circle(field.x, field.y, well + Layout.WELL_RIM, theme.wellRim));
        layer.fieldWells.add(new Circle(field.x, field.y, well, theme.ink));
        if (Metrics.entry(metric).style == STYLE_ZONE_SEGMENTS) {
            for (var i = 0; i < Layout.ZONE_SEGMENTS; i++) {
                layer.fieldTracks.add(zoneSegment(field, i, theme.gaugeTrack));
            }
        } else {
            layer.fieldTracks.add(arc(field.x, field.y, field.ringRadius, field.ringPen, 0, 360,
                theme.gaugeTrack));
        }
    }

    // The rounded rect moved in by `by` px on every side (out for a negative
    // `by`), its radius with it, in a new color.
    function inset(rect as RoundedRect, by as Number, color as Number) as RoundedRect {
        return new RoundedRect(rect.x + by, rect.y + by, rect.width - 2 * by,
            rect.height - 2 * by, rect.radius - by, color);
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
    // radius. Of the face config they depend only on the theme, so the
    // renderer gets them with the static layer when a face config is
    // applied; unlike the static layer they are drawn on every update, over
    // the progress (they are not in the buffer).
    function bezelNotches(config as ResolvedFaceConfig) as Array<Line> {
        var angles = Layout.BEZEL_NOTCHES;
        var notches = new Array<Line>[angles.size()];
        for (var i = 0; i < angles.size(); i++) {
            var inner = pointAt(angles[i], Layout.BEZEL_NOTCH_INNER);
            var outer = pointAt(angles[i], Layout.BEZEL_NOTCH_OUTER);
            notches[i] = new Line(inner[0], inner[1], outer[0], outer[1],
                Layout.BEZEL_NOTCH_PEN, config.theme.ink);
        }
        return notches;
    }

    // goal > 0, value known and value >= goal.
    function goalReached(value as Number?, goal as Number?) as Boolean {
        return value != null && goal != null && hasGoalProgress(value, goal) && value >= goal;
    }

    // Progress of a goal metric can be shown: the goal is above 0 and the
    // value is known (0 included). Both have been through the invalid-value
    // rule (Metrics.reading).
    function hasGoalProgress(value as Number?, goal as Number?) as Boolean {
        return value != null && goal != null && goal > 0;
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

    // Round caps (stories 27, 31, 32): a filled circle of radius pen / 2 in
    // the arc's color at each end of every arc, on its centerline. A full
    // circle has no ends and a sweep of 0 draws nothing, so neither gets caps.
    function roundCaps(arcs as Array<Arc>) as Array<Circle> {
        var caps = [] as Array<Circle>;
        for (var i = 0; i < arcs.size(); i++) {
            var a = arcs[i];
            if (a.sweep > 0 && a.sweep < 360) {
                var start = pointAround(a.x, a.y, toCiq(a.start), a.radius);
                var end = arcEnd(a);
                caps.add(new Circle(start[0], start[1], a.pen / 2, a.color));
                caps.add(new Circle(end[0], end[1], a.pen / 2, a.color));
            }
        }
        return caps;
    }

    // The point at the end of an arc, on its centerline: [x, y]. toCiq turns
    // Connect IQ degrees back into design degrees (it is its own inverse).
    function arcEnd(a as Arc) as Array<Number> {
        return pointAround(a.x, a.y, toCiq(a.end), a.radius);
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
        return pointAround(Layout.CENTER_X, Layout.CENTER_Y, designDegrees, distance);
    }

    // The point `distance` from (x, y) at `designDegrees`, rounded to whole
    // pixels: [x, y].
    function pointAround(x as Number, y as Number, designDegrees as Number,
            distance as Number) as Array<Number> {
        var angle = Math.toRadians(designDegrees);
        return [
            Math.round(x + distance * Math.sin(angle)).toNumber(),
            Math.round(y - distance * Math.cos(angle)).toNumber()
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

    // The date text: the weekday, a space and the day/month (dateParts).
    function dateText(snapshot as Snapshot) as String {
        return dateParts(snapshot)[DATE_TEXT];
    }

    // The date's parts, indexed by DATE_WEEKDAY, DATE_DAY_MONTH and
    // DATE_TEXT: the folded weekday, the date as dd/mm (each with a leading
    // zero, whatever the watch's date format, Q38) and the whole text
    // between them with a space. A name that is missing, empty or cannot be
    // folded, or that would make the pill wider than its maximum (Q33),
    // falls back to the English abbreviation of the weekday number.
    function dateParts(snapshot as Snapshot) as Array<String> {
        var dayMonth = snapshot.day.format("%02d") + "/" + snapshot.month.format("%02d");
        var name = foldWeekday(snapshot.weekdayName);
        if (name != null) {
            name = shortenVietnamese(name);
        }
        if (name != null && name.length() > 0) {
            var text = name + " " + dayMonth;
            if (datePillWidth(dateTextWidth(text)) <= Layout.DATE_PILL_MAX_WIDTH) {
                return [name, dayMonth, text] as Array<String>;
            }
        }
        var english = ENGLISH_WEEKDAYS[snapshot.weekdayNumber - 1];
        return [english, dayMonth, english + " " + dayMonth] as Array<String>;
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

    // The date's width as the design measures it: letter spacing only
    // between characters, so without the spacing the date font bakes in
    // after the last one. The date is centered and padded by this width.
    function dateTextWidth(text as String) as Number {
        var font = FontCatalog.entry(FONT_DATE);
        return textWidth(text, font) - font.letterSpacing;
    }

    // max(minimum, text width + 2 x pad) (Q23).
    function datePillWidth(textWidth as Number) as Number {
        var width = textWidth + 2 * Layout.DATE_PILL_PAD;
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
    // xadvance values. A glyph missing from the font counts as 0 (the
    // glyph-coverage test makes sure none is).
    function textWidth(text as String, font as FontEntry) as Number {
        var widths = font.widths;
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
