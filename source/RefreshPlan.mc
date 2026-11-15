import Toybox.Lang;

// The refresh plan: what the face reads, how often, and which part of a
// frame each kind of change makes stale. FaceModel derives all of it from
// the resolved face config (readPlan, invalidated); the data reader and the
// view only follow it.

// Which metrics the data reader reads while the screen is awake. Nothing is
// read in AOD but the clock (Q36). The battery is not in the plan: it is
// read once a minute and on every wake, whatever the face config.
class ReadPlan {
    // Read on every high-power update, about once a second (heart rate,
    // Q36), in metric order, each once.
    public var everySecond as Array<Metric>;
    // Read once a minute and on every wake (a goal metric with its goal), in
    // metric order, each once.
    public var everyMinute as Array<Metric>;
    // The heart-rate zones are read on every wake: a field draws zone
    // segments.
    public var zones as Boolean;

    function initialize(everySecond as Array<Metric>, everyMinute as Array<Metric>,
            zones as Boolean) {
        self.everySecond = everySecond;
        self.everyMinute = everyMinute;
        self.zones = zones;
    }
}

// What changed since a frame was computed, as bits: a set of change kinds
// is their bitwise or (a Number). A face config change counts as all of
// them.
enum ChangeKind {
    // The clock: hour, minute, date or weekday name.
    CHANGE_CLOCK = 1,
    // The minute data: everything read on a minute change or a wake (the
    // battery, the metrics read once a minute, the zones).
    CHANGE_MINUTE_DATA = 2,
    // A metric read every second.
    CHANGE_PER_SECOND = 4,
    // The clock's second, in high power only (Q41): never the hour or
    // minute, which are CHANGE_CLOCK.
    CHANGE_SECOND = 8,
    CHANGE_ALL = 15
}

// The parts of the frames that a set of change kinds can make stale, as
// bits; a set of parts is their bitwise or (a Number). One part per field,
// plus the time, the seconds, the date, the battery bar and the whole AOD
// frame.
enum FramePart {
    PART_LEFT = 1,
    PART_CENTER = 2,
    PART_RIGHT = 4,
    PART_BOTTOM = 8,
    PART_BEZEL_RING = 16,
    PART_TIME = 32,
    PART_DATE = 64,
    PART_BATTERY = 128,
    PART_AOD = 256,
    PART_SECONDS = 512
}
