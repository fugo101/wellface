import Toybox.Lang;
import Toybox.Test;

// The bezel ring (Q10, stories 18-26, 61, 70): 60 bezel ticks, lit by the
// goal metric's progress (steps) toward a white lead tick. Expected values
// come from the spec and decisions ("Final design: main elements", Bezel
// ring) and from the design's own stepRing and polar, computed outside the
// code (Python, double precision, as the design's JavaScript does).
(:test)
module BezelRingTest {
    function config() as ResolvedFaceConfig {
        return TestConfigs.mintDefault();
    }

    // Steps is the only goal metric, so the bezel ring shows it.
    function frameWithSteps(steps as Number?, goal as Number?) as Frame {
        var snapshot = new Snapshot(8, 42);
        snapshot.setValue(METRIC_STEPS, steps);
        snapshot.setGoal(METRIC_STEPS, goal);
        return FaceModel.compute(snapshot, config());
    }

    // The lead tick, asserted to be there.
    function leadOf(frame as Frame) as Line {
        var lead = frame.bezelLead;
        Test.assertMessage(lead != null, "no lead tick");
        return lead as Line;
    }

    function assertLine(line as Line, x1 as Number, y1 as Number, x2 as Number, y2 as Number,
            pen as Number, color as Number) as Void {
        Test.assertEqualMessage(line.x1, x1, "x1");
        Test.assertEqualMessage(line.y1, y1, "y1");
        Test.assertEqualMessage(line.x2, x2, "x2");
        Test.assertEqualMessage(line.y2, y2, "y2");
        Test.assertEqualMessage(line.pen, pen, "pen");
        Test.assertEqualMessage(line.color.format("%06X"), color.format("%06X"), "color");
    }

    // n lit ticks before the goal: ticks 0...n-2 in the comet, tick n-1 the
    // lead tick.
    function assertLitBeforeTheGoal(frame as Frame, n as Number) as Void {
        Test.assertEqualMessage(frame.bezelLit.size(), n - 1, "comet ticks");
        Test.assert(frame.bezelLead != null);
    }

    function assertUnlit(frame as Frame) as Void {
        Test.assertEqualMessage(frame.bezelLit.size(), 0, "lit ticks");
        Test.assert(frame.bezelLead == null);
    }

    // A frame in the named theme with `steps` of `goal`.
    function themedFrame(theme as String, steps as Number, goal as Number) as Frame {
        var snapshot = new Snapshot(8, 42);
        snapshot.setValue(METRIC_STEPS, steps);
        snapshot.setGoal(METRIC_STEPS, goal);
        return FaceModel.compute(snapshot, FaceModel.resolve(new FaceConfig(theme, METRIC_STRESS,
            METRIC_BODY_BATTERY, METRIC_HEART_RATE, METRIC_STEPS, METRIC_STEPS)));
    }

    function assertColor(what as String, expected as Number, actual as Number) as Void {
        Test.assertMessage(expected == actual, what + ": expected " + expected.format("%06X")
            + ", got " + actual.format("%06X"));
    }

    // ---- Lit count and lead tick ----

    // Story 25: no steps lights nothing.
    (:test)
    function zeroStepsLeaveEveryTickUnlit(logger as Test.Logger) as Boolean {
        assertUnlit(frameWithSteps(0, 3110));
        return true;
    }

    // Story 23: the first step lights the 12 o'clock tick as the lead tick:
    // white, from r 195 to r 208, pen max(4, 5).
    (:test)
    function oneStepLightsThe12OClockTickAsTheLeadTick(logger as Test.Logger) as Boolean {
        var frame = frameWithSteps(1, 3110);
        assertLitBeforeTheGoal(frame, 1);
        assertLine(leadOf(frame), 208, 13, 208, 0, 5, 0xFFFFFF);
        return true;
    }

    // Story 20: exactly 25/50/75% light the 3/6/9 o'clock tick (i = 15, 30,
    // 45) as the lead tick: n = floor(p x 60) + 1 = 16, 31, 46.
    (:test)
    function quartersLightThe3And6And9OClockTicksExactly(logger as Test.Logger) as Boolean {
        var frame = frameWithSteps(1000, 4000);
        assertLitBeforeTheGoal(frame, 16);
        assertLine(leadOf(frame), 403, 208, 416, 208, 5, 0xFFFFFF);
        frame = frameWithSteps(2000, 4000);
        assertLitBeforeTheGoal(frame, 31);
        assertLine(leadOf(frame), 208, 403, 208, 416, 5, 0xFFFFFF);
        frame = frameWithSteps(3000, 4000);
        assertLitBeforeTheGoal(frame, 46);
        assertLine(leadOf(frame), 13, 208, 0, 208, 5, 0xFFFFFF);
        return true;
    }

    // One step short of 25%: 999 x 60 / 4000 = 14.985, so tick 14 leads and
    // the 3 o'clock tick waits.
    (:test)
    function oneStepShortOfAQuarterLeavesTheQuarterTickUnlit(logger as Test.Logger)
            as Boolean {
        assertLitBeforeTheGoal(frameWithSteps(999, 4000), 15);
        return true;
    }

    // The design's frame 1: 1.147 of 3.110 steps (36.9%) lights 23 of 60.
    (:test)
    function frame1Lights23Ticks(logger as Test.Logger) as Boolean {
        assertLitBeforeTheGoal(frameWithSteps(1147, 3110), 23);
        return true;
    }

    // One step short of the goal: floor(59.98) + 1 = 60, so tick 59 leads,
    // white, pen max(4, 3) = 4: (187.62, 14.07) to (186.26, 1.14).
    (:test)
    function oneStepShortOfTheGoalLeadsWithTick59(logger as Test.Logger) as Boolean {
        var frame = frameWithSteps(3109, 3110);
        assertLitBeforeTheGoal(frame, 60);
        assertLine(leadOf(frame), 188, 14, 186, 1, 4, 0xFFFFFF);
        return true;
    }

    // Story 24: at the goal and above it, all 60 ticks in the accent and no
    // lead tick.
    (:test)
    function theGoalLightsAll60TicksInTheAccent(logger as Test.Logger) as Boolean {
        var steps = [3110, 3512, 100000] as Array<Number>;
        for (var s = 0; s < steps.size(); s++) {
            var frame = frameWithSteps(steps[s], 3110);
            Test.assertEqual(60, frame.bezelLit.size());
            Test.assert(frame.bezelLead == null);
            for (var i = 0; i < 60; i++) {
                Test.assertEqual(0x8EE3B8, frame.bezelLit[i].color);
            }
        }
        return true;
    }

    // Story 25, Q26: no goal, goal 0, missing or negative steps light
    // nothing (and never divide by zero).
    (:test)
    function missingDataLeavesEveryTickUnlit(logger as Test.Logger) as Boolean {
        assertUnlit(frameWithSteps(1147, null));
        assertUnlit(frameWithSteps(1147, 0));
        assertUnlit(frameWithSteps(null, 3110));
        assertUnlit(frameWithSteps(-1, 3110));
        assertUnlit(frameWithSteps(1147, -3110));
        return true;
    }

    // ---- Comet colors ----

    // The design's colors of the first (i = 0) and last (i = 21) comet tick
    // at n = 23 (1.147 of 3.110 steps), per theme in ThemeTest.NAMES order:
    // each accent channel x (0.45 + 0.55 x (i + 1) / n), rounded as the
    // design's Math.round.
    const FIRST_COMET = [0x436C57, 0x647332, 0x55614C, 0x306A72, 0x426279, 0x505A64,
        0x4D5579, 0x585079, 0x6B5073, 0x65686A] as Array<Number>;
    const LAST_COMET = [0x8BDEB4, 0xCFEC67, 0xB0C89C, 0x64DBEA, 0x89CAF9, 0xA5B8CF,
        0x9FB0F9, 0xB5A4F9, 0xDDA5ED, 0xD0D6DB] as Array<Number>;

    // Stories 21, 51, 69: the comet brightens from 12 o'clock toward the
    // lead tick, in every theme, equal to the design.
    (:test)
    function cometColorsEqualTheDesignInEveryTheme(logger as Test.Logger) as Boolean {
        var names = ThemeTest.NAMES;
        for (var t = 0; t < names.size(); t++) {
            var lit = themedFrame(names[t], 1147, 3110).bezelLit;
            Test.assertEqual(22, lit.size());
            assertColor(names[t] + " first", FIRST_COMET[t], lit[0].color);
            assertColor(names[t] + " last", LAST_COMET[t], lit[21].color);
        }
        return true;
    }

    // The 7 cases where exact integer rounding would be 1 higher in one
    // channel than the design's double-precision Math.round. Goal 600, so
    // (n - 1) x 10 steps light n ticks.
    (:test)
    function cometColorsMatchTheDesignWhereIntegerRoundingWouldNot(logger as Test.Logger)
            as Boolean {
        // theme, n, i, the design's color.
        var cases = [
            [Themes.SAGE, 22, 4, 0x67765C],
            [Themes.SAGE, 44, 9, 0x67765C],
            [Themes.SAGE, 41, 34, 0xA6BC93],
            [Themes.STEEL, 39, 8, 0x616D7A],
            [Themes.PERIWINKLE, 22, 4, 0x5E6793],
            [Themes.PERIWINKLE, 44, 9, 0x5E6793],
            [Themes.ORCHID, 39, 8, 0x82618C]
        ] as Array<Array>;
        for (var c = 0; c < cases.size(); c++) {
            var theme = cases[c][0] as String;
            var n = cases[c][1] as Number;
            var i = cases[c][2] as Number;
            var lit = themedFrame(theme, (n - 1) * 10, 600).bezelLit;
            Test.assertEqual(n - 1, lit.size());
            assertColor(theme + " n " + n + " i " + i, cases[c][3] as Number, lit[i].color);
        }
        return true;
    }

    // ---- Geometry ----

    function staticTicks() as Array<Line> {
        return FaceModel.staticLayer(config()).bezelTicks;
    }

    // Tick i at 6i deg clockwise from 12 o'clock, from its inner radius to
    // r 208, in whole pixels: (208 + r sin, 208 - r cos), rounded half up.
    // An ordinary tick: r 201, pen 3, unlit #343B37. Tick 1: (229.01, 8.10)
    // to (229.74, 1.14).
    (:test)
    function anOrdinaryTickRunsFromR201WithPen3(logger as Test.Logger) as Boolean {
        assertLine(staticTicks()[1], 229, 8, 230, 1, 3, 0x343B37);
        return true;
    }

    // Every 5th tick: r 198, pen 4, unlit #4A524D. Tick 5 (30 deg): (307.00,
    // 36.53) to (312.00, 27.87).
    (:test)
    function everyFifthTickRunsFromR198WithPen4(logger as Test.Logger) as Boolean {
        assertLine(staticTicks()[5], 307, 37, 312, 28, 4, 0x4A524D);
        return true;
    }

    // The ticks at 12, 3, 6 and 9 o'clock: r 196, pen 5, unlit #69736D.
    (:test)
    function quarterTicksRunFromR196WithPen5(logger as Test.Logger) as Boolean {
        var ticks = staticTicks();
        assertLine(ticks[0], 208, 12, 208, 0, 5, 0x69736D);
        assertLine(ticks[15], 404, 208, 416, 208, 5, 0x69736D);
        assertLine(ticks[30], 208, 404, 208, 416, 5, 0x69736D);
        assertLine(ticks[45], 12, 208, 0, 208, 5, 0x69736D);
        return true;
    }

    // 60 ticks: 4 at the quarters, 8 more every 5th, 48 ordinary.
    (:test)
    function theStaticLayerHoldsAll60UnlitTicks(logger as Test.Logger) as Boolean {
        var ticks = staticTicks();
        Test.assertEqual(60, ticks.size());
        var counts = { 0x343B37 => 0, 0x4A524D => 0, 0x69736D => 0 } as Dictionary<Number, Number>;
        for (var i = 0; i < ticks.size(); i++) {
            var color = ticks[i].color;
            Test.assert(counts.hasKey(color));
            counts[color] = (counts[color] as Number) + 1;
        }
        Test.assertEqual(48, counts[0x343B37]);
        Test.assertEqual(8, counts[0x4A524D]);
        Test.assertEqual(4, counts[0x69736D]);
        return true;
    }

    // The edge mask: a black ring r 201, pen 14 (r 194-208), all the way
    // round (a full circle in the arc contract: start == end).
    (:test)
    function theEdgeMaskIsABlackRingUnderTheTicks(logger as Test.Logger) as Boolean {
        var mask = FaceModel.staticLayer(config()).edgeMask;
        Test.assertEqual(208, mask.x);
        Test.assertEqual(208, mask.y);
        Test.assertEqual(201, mask.radius);
        Test.assertEqual(14, mask.pen);
        Test.assertEqual(360, mask.sweep);
        Test.assertEqual(mask.start, mask.end);
        Test.assertEqual(0x000000, mask.color);
        return true;
    }

    // Lit ticks are drawn over the unlit ones, on the same line with the
    // same pen.
    (:test)
    function litTicksLieOnTheUnlitTicks(logger as Test.Logger) as Boolean {
        var lit = frameWithSteps(3110, 3110).bezelLit;
        var unlit = staticTicks();
        for (var i = 0; i < 60; i++) {
            Test.assertEqual(unlit[i].x1, lit[i].x1);
            Test.assertEqual(unlit[i].y1, lit[i].y1);
            Test.assertEqual(unlit[i].x2, lit[i].x2);
            Test.assertEqual(unlit[i].y2, lit[i].y2);
            Test.assertEqual(unlit[i].pen, lit[i].pen);
        }
        return true;
    }

    // The lead tick reaches in to r 195 whatever its tier, with pen
    // max(4, own pen). Exact halves round up: tick 5 starts at (305.5,
    // 39.13), tick 10 at (376.87, 110.5). Goal 600, so 50 and 100 steps light
    // 6 and 11 ticks.
    (:test)
    function theLeadTickReachesInToR195(logger as Test.Logger) as Boolean {
        assertLine(leadOf(frameWithSteps(50, 600)), 306, 39, 312, 28, 4, 0xFFFFFF);
        assertLine(leadOf(frameWithSteps(100, 600)), 377, 111, 388, 104, 4, 0xFFFFFF);
        // Tick 1 (ordinary, pen 3 -> 4): (228.38, 14.07).
        assertLine(leadOf(frameWithSteps(10, 600)), 228, 14, 230, 1, 4, 0xFFFFFF);
        return true;
    }
}
