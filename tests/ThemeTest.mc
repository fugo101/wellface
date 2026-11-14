import Toybox.Lang;
import Toybox.Test;

// Themes (Q42): a theme is one accent, and every themed color is derived
// from it. Expected values are the hex values the final design publishes in
// its "Theme" row (shade() in the design's JavaScript), never recomputed
// here.
(:test)
module ThemeTest {
    // Indices into NAMES and ROLES.
    const MINT = 0;
    const VOLT = 1;
    const ORCHID = 8;
    // Indices into a ROLES row.
    const ACCENT = 0;
    const BACKGROUND = 1;
    const CONTOUR_TEXTURE = 2;
    const WELL_RIM = 3;
    const COMET_BASE = 4;
    const AOD = 5;
    // Indices into FIXED of the unlit tick colors the face does not draw yet
    // (every 5th, 12/3/6/9 o'clock).
    const TICK_UNLIT_FIFTH = 2;
    const TICK_UNLIT_QUARTER = 3;

    // The ten theme names, in the design's order.
    const NAMES = ["mint", "volt", "sage", "aqua", "glacier", "steel", "periwinkle", "lavender",
        "orchid", "platinum"] as Array<String>;
    // Per theme: accent, background (x 0.24), contour texture (x 0.36),
    // well rim (x 0.48), comet base (x 0.45), AOD (x 0.75).
    const ROLES = [
        [0x8EE3B8, 0x22362C, 0x335242, 0x446D58, 0x406653, 0x6BAA8A],
        [0xD4F26A, 0x333A19, 0x4C5726, 0x667433, 0x5F6D30, 0x9FB650],
        [0xB4CDA0, 0x2B3126, 0x414A3A, 0x56624D, 0x515C48, 0x879A78],
        [0x66E0F0, 0x18363A, 0x255156, 0x316C73, 0x2E656C, 0x4DA8B4],
        [0x8CCFFF, 0x22323D, 0x324B5C, 0x43637A, 0x3F5D73, 0x699BBF],
        [0xA9BDD4, 0x292D33, 0x3D444C, 0x515B66, 0x4C555F, 0x7F8E9F],
        [0xA3B4FF, 0x272B3D, 0x3B415C, 0x4E567A, 0x495173, 0x7A87BF],
        [0xB9A8FF, 0x2C283D, 0x433C5C, 0x59517A, 0x534C73, 0x8B7EBF],
        [0xE2A9F3, 0x36293A, 0x513D57, 0x6C5175, 0x664C6D, 0xAA7FB6],
        [0xD5DBE0, 0x333536, 0x4D4F51, 0x66696C, 0x606365, 0xA0A4A8]
    ] as Array<Array<Number> >;
    // The fixed roles (Q42), the same in every theme: gauge track, the three
    // unlit bezel tick colors (ordinary, every 5th, 12/3/6/9 o'clock), ink,
    // text, secondary, warning levels 1 and 2, zones 1-5.
    const FIXED = [0x2E3330, 0x343B37, 0x4A524D, 0x69736D, 0x000000, 0xFFFFFF, 0x8C8C8C,
        0xFF8A3D, 0xFF4D4D, 0xB4B4B4, 0x4DA6FF, 0x4CD964, 0xFF8A3D, 0xFF4D4D] as Array<Number>;

    function resolved(name as String) as Theme {
        return FaceModel.resolve(new FaceConfig(name, METRIC_STRESS, METRIC_BODY_BATTERY,
            METRIC_HEART_RATE, METRIC_STEPS, METRIC_STEPS)).theme;
    }

    function assertRole(name as String, role as String, expected as Number, actual as Number)
            as Void {
        Test.assertMessage(expected == actual, name + " " + role + ": expected "
            + expected.format("%06X") + ", got " + actual.format("%06X"));
    }

    function assertDerived(name as String, roles as Array<Number>, theme as Theme) as Void {
        assertRole(name, "accent", roles[ACCENT], theme.accent);
        assertRole(name, "background", roles[BACKGROUND], theme.background);
        assertRole(name, "contourTexture", roles[CONTOUR_TEXTURE], theme.contourTexture);
        assertRole(name, "wellRim", roles[WELL_RIM], theme.wellRim);
        assertRole(name, "cometBase", roles[COMET_BASE], theme.cometBase);
        assertRole(name, "aodColor", roles[AOD], theme.aodColor);
    }

    function assertFixed(name as String, theme as Theme) as Void {
        var actual = [theme.gaugeTrack, theme.tickUnlit, theme.tickUnlitFifth,
            theme.tickUnlitQuarter, theme.ink, theme.text, theme.secondary, theme.warningLevel1,
            theme.warningLevel2] as Array<Number>;
        Test.assertEqual(5, theme.zones.size());
        actual.addAll(theme.zones);
        for (var i = 0; i < FIXED.size(); i++) {
            assertRole(name, "fixed role " + i, FIXED[i], actual[i]);
        }
    }

    // Stories 49, 51, 52, 55, 69: each of the ten themes resolves by name,
    // every derived role equals the design's published value, and the fixed
    // roles are the same in every theme.
    (:test)
    function everyThemeResolvesByNameWithTheDesignsColors(logger as Test.Logger) as Boolean {
        for (var i = 0; i < NAMES.size(); i++) {
            var theme = resolved(NAMES[i]);
            assertDerived(NAMES[i], ROLES[i], theme);
            assertFixed(NAMES[i], theme);
        }
        return true;
    }
}
