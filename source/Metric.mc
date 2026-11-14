import Toybox.Complications;
import Toybox.Lang;

// The health and activity data a field can show (Q29). The metric, not the
// field, decides how its value is drawn. Everything about a metric lives in
// the metric module (Metrics); no other module switches on the metric.
// Indexes into Metrics.ALL and the snapshot's values: keep them 0, 1, 2, ...
enum Metric {
    METRIC_STRESS,
    METRIC_BODY_BATTERY,
    METRIC_HEART_RATE,
    METRIC_STEPS
}

// How a metric's value is drawn (glossary: drawing style). Field kinds accept
// only some of them (Q40, FieldKinds).
enum DrawingStyle {
    // One arc from 12 o'clock over the 0-100 range, on a full-ring track.
    STYLE_GAUGE,
    // One lit segment per heart-rate zone reached, on five unlit segments.
    STYLE_ZONE_SEGMENTS,
    // Progress toward a goal read from the watch.
    STYLE_GOAL_PROGRESS
}

// Where the data reader gets a metric's value.
enum ValueSource {
    // The metric's complication (MetricEntry.complication), polled.
    SOURCE_COMPLICATION,
    // The activity info: today's steps, and the step goal as the goal.
    SOURCE_ACTIVITY_STEPS
}

// How often the data reader reads a metric while the screen is awake, when
// the face config shows it (FaceModel.readPlan; nothing is read in AOD, Q36).
enum ReadCadence {
    // On every high-power update, about once a second.
    CADENCE_EVERY_SECOND,
    // Once a minute and on every wake.
    CADENCE_EVERY_MINUTE
}

// How a metric's number (and its goal) is written.
enum NumberFormat {
    // Plain digits: 1147.
    NUMBER_FORMAT_PLAIN,
    // A dot every three digits: 1.147.
    NUMBER_FORMAT_DOT_THOUSANDS
}

// Everything about one metric, described once.
class MetricEntry {
    public var style as DrawingStyle;
    // Code point of its icon in the icon font.
    public var icon as Number;
    public var source as ValueSource;
    // The complication read for its value (SOURCE_COMPLICATION) and the one
    // whose Garmin page a long press opens.
    public var complication as Complications.Type;
    public var cadence as ReadCadence;
    // The warning thresholds (Q3): level 1 when the value is beyond
    // warningLevel1, level 2 when beyond warningLevel2, "beyond" meaning
    // above for warningAbove and below otherwise (strictly). Null for a
    // metric without warnings.
    public var warningAbove as Boolean;
    public var warningLevel1 as Number?;
    public var warningLevel2 as Number?;
    public var format as NumberFormat;
    // A gauge ends in a white dot when the value is above 0 (Body Battery,
    // story 29).
    public var gaugeEndDot as Boolean;

    function initialize(style as DrawingStyle, icon as Number, source as ValueSource,
            complication as Complications.Type, cadence as ReadCadence, warningAbove as Boolean,
            warningLevel1 as Number?, warningLevel2 as Number?, format as NumberFormat,
            gaugeEndDot as Boolean) {
        self.style = style;
        self.icon = icon;
        self.source = source;
        self.complication = complication;
        self.cadence = cadence;
        self.warningAbove = warningAbove;
        self.warningLevel1 = warningLevel1;
        self.warningLevel2 = warningLevel2;
        self.format = format;
        self.gaugeEndDot = gaugeEndDot;
    }
}

// The metric module: the only place that knows what each metric is. Values
// are those of Q3 (warnings), Q6 (the step goal), Q11 and Q37 (zones), Q26
// (missing data) and Q36 (heart rate every second).
module Metrics {
    // Every metric, in enum order.
    const ALL = [METRIC_STRESS, METRIC_BODY_BATTERY, METRIC_HEART_RATE, METRIC_STEPS]
        as Array<Metric>;

    // Built on first use, then kept; indexed by metric.
    var _entries as Array<MetricEntry>? = null;

    function entry(metric as Metric) as MetricEntry {
        var all = _entries;
        if (all == null) {
            all = [
                // Stress: orange at 51-75, red above 75.
                new MetricEntry(STYLE_GAUGE, FontCatalog.ICON_STRESS, SOURCE_COMPLICATION,
                    Complications.COMPLICATION_TYPE_STRESS, CADENCE_EVERY_MINUTE, true, 50, 75,
                    NUMBER_FORMAT_PLAIN, false),
                // Body Battery: orange at 15-24, red below 15.
                new MetricEntry(STYLE_GAUGE, FontCatalog.ICON_BOLT, SOURCE_COMPLICATION,
                    Complications.COMPLICATION_TYPE_BODY_BATTERY, CADENCE_EVERY_MINUTE, false,
                    25, 15, NUMBER_FORMAT_PLAIN, true),
                // Heart rate: zone colors instead of warnings.
                new MetricEntry(STYLE_ZONE_SEGMENTS, FontCatalog.ICON_HEART, SOURCE_COMPLICATION,
                    Complications.COMPLICATION_TYPE_HEART_RATE, CADENCE_EVERY_SECOND, false,
                    null, null, NUMBER_FORMAT_PLAIN, false),
                // Steps: the watch's own (auto) step goal instead of warnings.
                new MetricEntry(STYLE_GOAL_PROGRESS, FontCatalog.ICON_FOOT,
                    SOURCE_ACTIVITY_STEPS, Complications.COMPLICATION_TYPE_STEPS,
                    CADENCE_EVERY_MINUTE, false, null, null, NUMBER_FORMAT_DOT_THOUSANDS, false)
            ] as Array<MetricEntry>;
            _entries = all;
        }
        return all[metric];
    }

    // A goal metric has a goal read from the watch, and it is exactly the
    // metric drawn as goal progress: the style decides both, so they never
    // disagree.
    function isGoalMetric(metric as Metric) as Boolean {
        return entry(metric).style == STYLE_GOAL_PROGRESS;
    }

    // Read on every high-power update (heart rate, Q36), rather than once a
    // minute.
    function readsEverySecond(metric as Metric) as Boolean {
        return entry(metric).cadence == CADENCE_EVERY_SECOND;
    }

    // The heart-rate zones are needed exactly to draw zone segments.
    function needsZones(metric as Metric) as Boolean {
        return entry(metric).style == STYLE_ZONE_SEGMENTS;
    }

    // The invalid-value rule, the same for every metric and its goal (Q26):
    // a negative reading is no reading.
    function reading(value as Number?) as Number? {
        return value != null && value >= 0 ? value : null;
    }

    // The warning level of a value: 0 (none), 1 or 2.
    function warningLevel(metric as Metric, value as Number) as Number {
        var e = entry(metric);
        var level1 = e.warningLevel1;
        var level2 = e.warningLevel2;
        if (level2 != null && beyond(value, level2, e.warningAbove)) {
            return 2;
        }
        return level1 != null && beyond(value, level1, e.warningAbove) ? 1 : 0;
    }

    function beyond(value as Number, limit as Number, above as Boolean) as Boolean {
        return above ? value > limit : value < limit;
    }

    // A non-negative value (or goal) of a metric as text.
    function format(metric as Metric, value as Number) as String {
        return entry(metric).format == NUMBER_FORMAT_DOT_THOUSANDS
            ? formatThousands(value) : value.toString();
    }

    // A non-negative number with a dot every three digits: 1147 -> "1.147".
    function formatThousands(value as Number) as String {
        if (value < 1000) {
            return value.toString();
        }
        return formatThousands(value / 1000) + "." + (value % 1000).format("%03d");
    }
}
