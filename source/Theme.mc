import Toybox.Lang;

// A theme (glossary): one accent, from which every themed color is derived
// on construction (Q42), plus the colors that stay the same in every theme.
// Every color on the face comes from the active theme, so layout and logic
// never name a concrete color. The one exception is the black of Always On
// (Q17), a platform rule: FaceModel.AOD_BLACK.
class Theme {
    // --- Themed roles: the accent and the colors derived from it. ---

    // Time band, gauges and bezel progress, lit battery segments,
    // goal-reached field.
    public var accent as Number;
    // The background disc: accent x 0.24.
    public var background as Number;
    // The contour texture (Q43): accent x 0.36. Not drawn yet.
    public var contourTexture as Number;
    // Well rims (Q39): accent x 0.48, lighter than the background.
    public var wellRim as Number;
    // The comet's base (Q10): accent x 0.45, the dim end the lit bezel ticks
    // fade toward. Never drawn by itself.
    public var cometBase as Number;
    // Always On time and date (Q13): accent x 0.75.
    public var aodColor as Number;

    // --- Fixed roles: the same in every theme. ---

    // Gauge tracks, unlit zone segments, unlit battery segments.
    public var gaugeTrack as Number = 0x2E3330;
    // Unlit bezel ticks: ordinary, every 5th, and at 12/3/6/9 o'clock. The
    // ordinary color also draws the bezel ring track for now.
    public var tickUnlit as Number = 0x343B37;
    public var tickUnlitFifth as Number = 0x4A524D;
    public var tickUnlitQuarter as Number = 0x69736D;
    // Wells, time digits, notches, date pill and bottom field fill.
    public var ink as Number = 0x000000;
    // Numbers, date text, bezel head dot.
    public var text as Number = 0xFFFFFF;
    // Icons without a warning, "/ goal", "--".
    public var secondary as Number = 0x8C8C8C;
    // Warning levels 1 (orange) and 2 (red) (Q3).
    public var warningLevel1 as Number = 0xFF8A3D;
    public var warningLevel2 as Number = 0xFF4D4D;
    // Heart-rate zones 1-5, one color each, in Garmin's order: gray, blue,
    // green, orange, red (Q37). Lit zone segments only. Garmin publishes the
    // color names only; these values were chosen to read well on the dark
    // background.
    public var zones as Array<Number> =
        [0xB4B4B4, 0x4DA6FF, 0x4CD964, 0xFF8A3D, 0xFF4D4D] as Array<Number>;

    function initialize(accent as Number) {
        self.accent = accent;
        background = Themes.shade(accent, 24);
        contourTexture = Themes.shade(accent, 36);
        wellRim = Themes.shade(accent, 48);
        cometBase = Themes.shade(accent, 45);
        aodColor = Themes.shade(accent, 75);
    }
}

module Themes {
    // Theme names, as a face config names them (the design's theme ids).
    // Switching the face's theme means naming another one in
    // FaceConfigs.defaultConfig.
    const MINT = "mint";
    const VOLT = "volt";
    const SAGE = "sage";
    const AQUA = "aqua";
    const GLACIER = "glacier";
    const STEEL = "steel";
    const PERIWINKLE = "periwinkle";
    const LAVENDER = "lavender";
    const ORCHID = "orchid";
    const PLATINUM = "platinum";

    // The ten themes (Q42): each name and its accent, in the design's order.
    const NAMES = [MINT, VOLT, SAGE, AQUA, GLACIER, STEEL, PERIWINKLE, LAVENDER, ORCHID,
        PLATINUM] as Array<String>;
    const ACCENTS = [0x8EE3B8, 0xD4F26A, 0xB4CDA0, 0x66E0F0, 0x8CCFFF, 0xA9BDD4, 0xA3B4FF,
        0xB9A8FF, 0xE2A9F3, 0xD5DBE0] as Array<Number>;

    // The theme with this name, null when there is none. FaceModel.resolve
    // turns an unknown name into the default theme.
    function named(name as String) as Theme? {
        for (var i = 0; i < NAMES.size(); i++) {
            if (name.equals(NAMES[i])) {
                return new Theme(ACCENTS[i]);
            }
        }
        return null;
    }

    // The default theme (Q9): an unknown name resolves to it.
    function mint() as Theme {
        return named(MINT) as Theme;
    }

    // The theme derivation (Q42): each RGB channel x percent / 100, rounded
    // half up in integer math. Matches the design's Math.round for every
    // role of the ten themes.
    function shade(color as Number, percent as Number) as Number {
        var shaded = 0;
        for (var shift = 16; shift >= 0; shift -= 8) {
            var channel = (color >> shift) & 0xFF;
            shaded |= ((channel * percent + 50) / 100) << shift;
        }
        return shaded;
    }
}
