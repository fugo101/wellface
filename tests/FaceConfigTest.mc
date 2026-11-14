import Toybox.Lang;
import Toybox.Test;

// Resolving a face config (Q40): the theme is looked up by name, a metric a
// field cannot draw falls back to that field's default metric, and FaceModel
// says which metrics each field accepts. Expected values are the mint
// theme's colors and today's mapping (Q29).
(:test)
module FaceConfigTest {
    const FIELDS = Layout.FIELDS;

    // Every mint value, the mint AOD color (the accent at 75%) included.
    const MINT_VALUES = [0x8EE3B8, 0x2C332F, 0x4D5852, 0x343B37, 0x2E3330, 0x000000, 0xFFFFFF,
        0x8C8C8C, 0xFF8A3D, 0xFF4D4D, 0xB4B4B4, 0x4DA6FF, 0x4CD964, 0x6BAA8A] as Array<Number>;
    // The test theme's roles, in constructor order, then its zones.
    const TEST_VALUES = [0x103050, 0x202020, 0x303030, 0x404040, 0x505050, 0x606060, 0x707070,
        0x808080, 0x909090, 0xA0A0A0, 0xB0B0B0, 0xC0C0C0, 0xD0D0D0, 0xE0E0E0, 0xF0F0F0]
        as Array<Number>;
    // The test accent at 75%, worked by hand: 0x10, 0x30, 0x50 -> 12, 36, 60.
    const TEST_AOD = 0x0C243C;

    // Today's face, in field order.
    const DEFAULT_METRICS = [METRIC_STRESS, METRIC_BODY_BATTERY, METRIC_HEART_RATE,
        METRIC_STEPS, METRIC_STEPS] as Array<Metric>;

    function assertMetrics(expected as Array<Metric>, config as ResolvedFaceConfig) as Void {
        for (var f = 0; f < FIELDS.size(); f++) {
            Test.assertMessage(expected[f] == config.metricOf(FIELDS[f]),
                "field " + FIELDS[f] + ": expected metric " + expected[f] + ", got "
                    + config.metricOf(FIELDS[f]));
        }
    }

    // The mint theme, role by role.
    function assertMint(theme as Theme) as Void {
        Test.assertEqual(0x8EE3B8, theme.accent);
        Test.assertEqual(0x2C332F, theme.background);
        Test.assertEqual(0x4D5852, theme.wellRim);
        Test.assertEqual(0x343B37, theme.bezelTrack);
        Test.assertEqual(0x2E3330, theme.gaugeTrack);
        Test.assertEqual(0x000000, theme.ink);
        Test.assertEqual(0xFFFFFF, theme.text);
        Test.assertEqual(0x8C8C8C, theme.secondary);
        Test.assertEqual(0xFF8A3D, theme.warningLevel1);
        Test.assertEqual(0xFF4D4D, theme.warningLevel2);
        var zones = [0xB4B4B4, 0x4DA6FF, 0x4CD964, 0xFF8A3D, 0xFF4D4D] as Array<Number>;
        Test.assertEqual(zones.size(), theme.zones.size());
        for (var i = 0; i < zones.size(); i++) {
            Test.assertEqual(zones[i], theme.zones[i]);
        }
    }

    function resolve(theme as String, left as Metric, center as Metric, right as Metric,
            bottom as Metric, bezelRing as Metric) as ResolvedFaceConfig {
        return FaceModel.resolve(new FaceConfig(theme, left, center, right, bottom, bezelRing));
    }

    // Stories 1, 24: the built-in default is today's face: the mint theme;
    // stress, Body Battery, heart rate, steps, steps.
    (:test)
    function defaultConfigIsTodaysFace(logger as Test.Logger) as Boolean {
        var config = FaceModel.resolve(FaceConfigs.defaultConfig());
        assertMint(config.theme);
        assertMetrics(DEFAULT_METRICS, config);
        return true;
    }

    // Story 20: the theme is looked up by its name.
    (:test)
    function themeIsLookedUpByName(logger as Test.Logger) as Boolean {
        assertMint(resolve("mint", METRIC_STRESS, METRIC_BODY_BATTERY, METRIC_HEART_RATE,
            METRIC_STEPS, METRIC_STEPS).theme);
        return true;
    }

    // An unknown theme name gives the default theme; the fields are kept.
    (:test)
    function unknownThemeGivesTheDefaultTheme(logger as Test.Logger) as Boolean {
        var names = ["", "Mint", "no such theme"] as Array<String>;
        for (var i = 0; i < names.size(); i++) {
            var config = resolve(names[i], METRIC_HEART_RATE, METRIC_STRESS, METRIC_BODY_BATTERY,
                METRIC_STEPS, METRIC_STEPS);
            assertMint(config.theme);
            assertMetrics([METRIC_HEART_RATE, METRIC_STRESS, METRIC_BODY_BATTERY, METRIC_STEPS,
                METRIC_STEPS] as Array<Metric>, config);
        }
        return true;
    }

    // Story 18 (Q40): steps in a round field falls back to that field's
    // default metric, one field at a time; the other fields are kept.
    (:test)
    function stepsInARoundFieldFallsBackToTheFieldsDefault(logger as Test.Logger) as Boolean {
        // Every round field asks for heart rate, except the one asking for steps.
        var expected = [
            [METRIC_STRESS, METRIC_HEART_RATE, METRIC_HEART_RATE, METRIC_STEPS, METRIC_STEPS],
            [METRIC_HEART_RATE, METRIC_BODY_BATTERY, METRIC_HEART_RATE, METRIC_STEPS,
                METRIC_STEPS],
            [METRIC_HEART_RATE, METRIC_HEART_RATE, METRIC_HEART_RATE, METRIC_STEPS, METRIC_STEPS]
        ] as Array<Array<Metric> >;
        assertMetrics(expected[0], resolve("mint", METRIC_STEPS, METRIC_HEART_RATE,
            METRIC_HEART_RATE, METRIC_STEPS, METRIC_STEPS));
        assertMetrics(expected[1], resolve("mint", METRIC_HEART_RATE, METRIC_STEPS,
            METRIC_HEART_RATE, METRIC_STEPS, METRIC_STEPS));
        assertMetrics(expected[2], resolve("mint", METRIC_HEART_RATE, METRIC_HEART_RATE,
            METRIC_STEPS, METRIC_STEPS, METRIC_STEPS));
        // All three at once.
        assertMetrics(DEFAULT_METRICS, resolve("mint", METRIC_STEPS, METRIC_STEPS, METRIC_STEPS,
            METRIC_STEPS, METRIC_STEPS));
        return true;
    }

    // Stories 16-18 (Q40): stress, Body Battery or heart rate in the bottom
    // field or on the bezel ring falls back to steps there.
    (:test)
    function nonGoalMetricOnAGoalFieldFallsBackToSteps(logger as Test.Logger) as Boolean {
        var round = [METRIC_STRESS, METRIC_BODY_BATTERY, METRIC_HEART_RATE] as Array<Metric>;
        for (var i = 0; i < round.size(); i++) {
            var m = round[i];
            // The round fields ask for something valid and not the default,
            // so a field reset by mistake would show.
            var asked = [METRIC_HEART_RATE, METRIC_STRESS, METRIC_BODY_BATTERY] as Array<Metric>;
            var kept = [METRIC_HEART_RATE, METRIC_STRESS, METRIC_BODY_BATTERY, METRIC_STEPS,
                METRIC_STEPS] as Array<Metric>;
            assertMetrics(kept, resolve("mint", asked[0], asked[1], asked[2], m, METRIC_STEPS));
            assertMetrics(kept, resolve("mint", asked[0], asked[1], asked[2], METRIC_STEPS, m));
            assertMetrics(kept, resolve("mint", asked[0], asked[1], asked[2], m, m));
        }
        return true;
    }

    // Story 14: the same metric may be in several fields.
    (:test)
    function duplicateMetricsAreAllowed(logger as Test.Logger) as Boolean {
        var round = [METRIC_STRESS, METRIC_BODY_BATTERY, METRIC_HEART_RATE] as Array<Metric>;
        for (var i = 0; i < round.size(); i++) {
            var m = round[i];
            assertMetrics([m, m, m, METRIC_STEPS, METRIC_STEPS] as Array<Metric>,
                resolve("mint", m, m, m, METRIC_STEPS, METRIC_STEPS));
        }
        return true;
    }

    // Story 19: each round field accepts stress, Body Battery and heart rate;
    // the bottom field and the bezel ring accept steps. In metric order.
    (:test)
    function acceptedMetricsPerField(logger as Test.Logger) as Boolean {
        var round = [METRIC_STRESS, METRIC_BODY_BATTERY, METRIC_HEART_RATE] as Array<Metric>;
        var goal = [METRIC_STEPS] as Array<Metric>;
        for (var f = 0; f < FIELDS.size(); f++) {
            var expected = f < 3 ? round : goal;
            var accepted = FaceModel.acceptedMetrics(FIELDS[f]);
            Test.assertMessage(expected.size() == accepted.size(),
                "field " + FIELDS[f] + ": " + accepted.size() + " metrics");
            for (var m = 0; m < expected.size(); m++) {
                Test.assertEqual(expected[m], accepted[m]);
            }
        }
        return true;
    }

    // A theme whose every role differs from mint's, and from each other.
    function testTheme() as Theme {
        return new Theme(0x103050, 0x202020, 0x303030, 0x404040, 0x505050, 0x606060, 0x707070,
            0x808080, 0x909090, 0xA0A0A0,
            [0xB0B0B0, 0xC0C0C0, 0xD0D0D0, 0xE0E0E0, 0xF0F0F0] as Array<Number>);
    }

    function addArcs(colors as Array<Number>, arcs as Array<Arc>) as Void {
        for (var i = 0; i < arcs.size(); i++) {
            colors.add(arcs[i].color);
        }
    }

    function addCircles(colors as Array<Number>, circles as Array<Circle>) as Void {
        for (var i = 0; i < circles.size(); i++) {
            colors.add(circles[i].color);
        }
    }

    // Every color of a frame, member by member, of what is drawn (an empty
    // text or arc list draws nothing).
    function frameColors(frame as Frame) as Array<Number> {
        var colors = [frame.timeColor, frame.dateColor, frame.datePill.color,
            frame.bezelProgress.color] as Array<Number>;
        addArcs(colors, frame.batteryLit);
        var head = frame.bezelHead;
        if (head != null) {
            colors.add(head.color);
        }
        var bottom = frame.bottomField;
        colors.add(bottom.pill.color);
        colors.add(bottom.numberColor);
        if (bottom.icon.length() > 0) {
            colors.add(bottom.iconColor);
        }
        if (bottom.goal.length() > 0) {
            colors.add(bottom.goalColor);
        }
        var fields = [frame.leftField, frame.centerField, frame.rightField] as Array<FieldFrame>;
        for (var i = 0; i < fields.size(); i++) {
            addArcs(colors, fields[i].arcs);
            colors.add(fields[i].iconColor);
            colors.add(fields[i].numberColor);
        }
        return colors;
    }

    // Every color of the static layer and the notches, member by member.
    function staticColors(layer as StaticLayer, notches as Array<Line>) as Array<Number> {
        var colors = [layer.backgroundColor, layer.timeBandRim.color, layer.bottomFieldRim.color,
            layer.timeBandWell.color, layer.timeBand.color, layer.bezelTrack.color,
            layer.batteryWell.color] as Array<Number>;
        addCircles(colors, layer.fieldRims);
        addCircles(colors, layer.batteryCaps);
        addArcs(colors, layer.batteryTrack);
        addCircles(colors, layer.fieldWells);
        addArcs(colors, layer.fieldTracks);
        for (var i = 0; i < notches.size(); i++) {
            colors.add(notches[i].color);
        }
        return colors;
    }

    // Snapshots that between them use every role: values known, warnings at
    // level 1 and 2 (heart rate in zone 5), the goal reached, and missing data.
    function themeSnapshots() as Array<Snapshot> {
        var zones = [96, 115, 134, 154, 173, 192] as Array<Number>;
        var values = [
            // battery, stress, Body Battery, heart rate, steps
            [64, 27, 56, 128, 1147],
            [15, 60, 20, 100, 1147],
            [5, 80, 10, 180, 1147],
            [64, 27, 56, 128, 3110]
        ] as Array<Array<Number> >;
        var snapshots = [new Snapshot(8, 42)] as Array<Snapshot>;
        for (var i = 0; i < values.size(); i++) {
            var s = new Snapshot(8, 42);
            s.weekdayName = "Thu";
            s.weekdayNumber = 5;
            s.day = 12;
            s.month = 11;
            s.heartRateZones = zones;
            s.battery = values[i][0];
            s.setValue(METRIC_STRESS, values[i][1]);
            s.setValue(METRIC_BODY_BATTERY, values[i][2]);
            s.setValue(METRIC_HEART_RATE, values[i][3]);
            s.setValue(METRIC_STEPS, values[i][4]);
            s.setGoal(METRIC_STEPS, 3110);
            snapshots.add(s);
        }
        return snapshots;
    }

    function assertThemeColors(colors as Array<Number>, allowed as Array<Number>,
            what as String) as Void {
        for (var i = 0; i < colors.size(); i++) {
            Test.assertMessage(allowed.indexOf(colors[i]) >= 0,
                what + " color " + colors[i].format("%06X") + " is not the test theme's");
            Test.assertMessage(MINT_VALUES.indexOf(colors[i]) < 0,
                what + " color " + colors[i].format("%06X") + " is a mint value");
        }
    }

    // Story 20: every color of the frame, the AOD frame, the static layer and
    // the bezel notches comes from the theme the config names. The AOD
    // frame's only other color is the black of Always On (Q17).
    (:test)
    function everyColorComesFromTheTheme(logger as Test.Logger) as Boolean {
        var config = FaceModel.resolve(FaceConfigs.defaultConfig());
        config.theme = testTheme();
        var used = staticColors(FaceModel.staticLayer(config), FaceModel.bezelNotches(config));
        assertThemeColors(used, TEST_VALUES, "static");
        var snapshots = themeSnapshots();
        for (var i = 0; i < snapshots.size(); i++) {
            var colors = frameColors(FaceModel.compute(snapshots[i], config));
            assertThemeColors(colors, TEST_VALUES, "frame " + i);
            used.addAll(colors);

            var aod = FaceModel.computeAod(snapshots[i], config);
            assertThemeColors([aod.timeColor, aod.dateColor, aod.datePill.color] as Array<Number>,
                [TEST_AOD] as Array<Number>, "AOD " + i);
            Test.assertEqual(0x000000, aod.datePillInner.color);
        }
        // The snapshots use every role, so none is left untested.
        for (var i = 0; i < TEST_VALUES.size(); i++) {
            Test.assertMessage(used.indexOf(TEST_VALUES[i]) >= 0,
                "role " + i + " is not used");
        }
        return true;
    }
}
