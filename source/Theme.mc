import Toybox.Lang;

// A named set of color roles. Every color on the face comes from the active
// theme, so layout and logic never name a concrete color.
class Theme {
    // Time band, gauge and bezel progress, lit battery segments, goal-reached
    // field.
    public var accent as Number;
    // The background disc.
    public var background as Number;
    // The bezel ring track only.
    public var bezelTrack as Number;
    // Gauge tracks, unlit zone segments, unlit battery segments.
    public var gaugeTrack as Number;
    // Wells, time digits, notches, date pill and bottom field fill.
    public var ink as Number;
    // Numbers, date text, bezel head dot.
    public var text as Number;
    // Icons without a warning, "/ goal", "--".
    public var secondary as Number;
    // Warning level 1 (orange in the mint theme).
    public var warningLevel1 as Number;
    // Warning level 2 (red in the mint theme).
    public var warningLevel2 as Number;
    // Heart-rate zones 1-5, one color each, in Garmin's order: gray, blue,
    // green, orange, red (Q37). Lit zone segments only.
    public var zones as Array<Number>;

    function initialize(
        accent as Number,
        background as Number,
        bezelTrack as Number,
        gaugeTrack as Number,
        ink as Number,
        text as Number,
        secondary as Number,
        warningLevel1 as Number,
        warningLevel2 as Number,
        zones as Array<Number>
    ) {
        self.accent = accent;
        self.background = background;
        self.bezelTrack = bezelTrack;
        self.gaugeTrack = gaugeTrack;
        self.ink = ink;
        self.text = text;
        self.secondary = secondary;
        self.warningLevel1 = warningLevel1;
        self.warningLevel2 = warningLevel2;
        self.zones = zones;
    }
}

module Themes {
    // The MVP's only theme. The active theme is hard-coded for now.
    function mint() as Theme {
        return new Theme(
            0x8EE3B8, // accent
            0x1A1D1B, // background
            0x1E1E1E, // bezelTrack
            0x2E3330, // gaugeTrack
            0x000000, // ink
            0xFFFFFF, // text
            0x8C8C8C, // secondary
            0xFF8A3D, // warningLevel1
            0xFF4D4D, // warningLevel2
            // zones 1-5. Garmin publishes the color names only; these values
            // were chosen to read well on the dark background.
            [0xB4B4B4, 0x4DA6FF, 0x4CD964, 0xFF8A3D, 0xFF4D4D] as Array<Number>
        );
    }

    function active() as Theme {
        return mint();
    }
}
