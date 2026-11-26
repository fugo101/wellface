import Toybox.Lang;
import Toybox.Test;

// The seconds (Q41, stories 4-10, 59, 63): two digits after the minutes
// while the screen is awake, Manrope ExtraBold 26 left-aligned at x 309 on
// the time's baseline y 155, in the ink color; never in Always On. Expected
// positions come from the design (x 309, baseline 155) and the 26 px number
// font's own file (resources/fonts/number26.fnt: base 28).
(:test)
module SecondsTest {
    function config() as ResolvedFaceConfig {
        return TestConfigs.mintDefault();
    }

    function at(second as Number) as Snapshot {
        var s = new Snapshot(8, 42);
        s.second = second;
        return s;
    }

    // ---- The seconds string and its place ----

    // Story 6: always two digits.
    (:test)
    function secondsAreAlwaysTwoDigits(logger as Test.Logger) as Boolean {
        Test.assertEqual("00", FaceModel.compute(at(0), config()).seconds);
        Test.assertEqual("07", FaceModel.compute(at(7), config()).seconds);
        Test.assertEqual("59", FaceModel.compute(at(59), config()).seconds);
        return true;
    }

    // Stories 5, 7: left-aligned at x 309, so the hours and minutes never
    // move; the line top is the baseline 155 minus the font's base 28; in
    // the ink, like the time.
    (:test)
    function secondsSitAfterTheMinutesOnTheTimesBaseline(logger as Test.Logger) as Boolean {
        var seconds = [0, 11, 59] as Array<Number>;
        for (var i = 0; i < seconds.size(); i++) {
            var frame = FaceModel.compute(at(seconds[i]), config());
            Test.assertEqual(309, frame.secondsX);
            Test.assertEqual(127, frame.secondsY);
            Test.assertEqual(0x000000, frame.secondsColor);
            Test.assertEqual(114, frame.timeX);
        }
        return true;
    }

    // Q41: no seconds while the face sleeps. The FR265 stops the per-second
    // updates about 10 s after a wake (onEnterSleep) even when a tap keeps
    // the screen lit, so the reader reports the second as unknown then, and
    // the seconds are hidden rather than left frozen.
    (:test)
    function noSecondsWhileTheFaceSleeps(logger as Test.Logger) as Boolean {
        var asleep = at(0);
        asleep.second = null;
        Test.assertEqual("", FaceModel.compute(asleep, config()).seconds);
        // A second change to unknown takes the seconds' fast path and still
        // equals a full compute; and back again on the next wake.
        var frame = FaceModel.compute(at(37), config());
        frame = FaceModel.update(frame, asleep, config(), CHANGE_SECOND);
        Test.assertEqual(FrameEquality.describeFrame(FaceModel.compute(asleep, config())),
            FrameEquality.describeFrame(frame));
        frame = FaceModel.update(frame, at(12), config(), CHANGE_SECOND);
        Test.assertEqual("12", frame.seconds);
        return true;
    }

    // ---- Refresh plan ----

    // The new change kind invalidates exactly the seconds: never the time,
    // the date, a field or the AOD frame.
    (:test)
    function aSecondChangeInvalidatesOnlyTheSeconds(logger as Test.Logger) as Boolean {
        var configs = TestConfigs.accepted();
        for (var i = 0; i < configs.size(); i++) {
            Test.assertEqual(PART_SECONDS, FaceModel.invalidated(CHANGE_SECOND, configs[i]));
        }
        return true;
    }

    // The seconds change with the clock's second only.
    (:test)
    function noOtherChangeInvalidatesTheSeconds(logger as Test.Logger) as Boolean {
        var others = CHANGE_CLOCK | CHANGE_MINUTE_DATA | CHANGE_PER_SECOND;
        Test.assertEqual(0, FaceModel.invalidated(others, config()) & PART_SECONDS);
        return true;
    }

    // Story 59: from a frame at every second, an update to every other
    // second with only CHANGE_SECOND equals a full computation, a heart-rate
    // field included.
    (:test)
    function aSecondsOnlyUpdateEqualsAFullComputation(logger as Test.Logger) as Boolean {
        var seconds = [0, 7, 11, 59] as Array<Number>;
        for (var a = 0; a < seconds.size(); a++) {
            for (var b = 0; b < seconds.size(); b++) {
                var from = RefreshPlanTest.typical();
                from.second = seconds[a];
                var to = RefreshPlanTest.typical();
                to.second = seconds[b];
                var previous = FaceModel.compute(from, config());
                var updated = FaceModel.update(previous, to, config(), CHANGE_SECOND);
                Test.assertEqualMessage(FrameEquality.describeFrame(updated),
                    FrameEquality.describeFrame(FaceModel.compute(to, config())),
                    "" + seconds[a] + " -> " + seconds[b]);
            }
        }
        return true;
    }

    // Story 59: a second change alone sets the seconds and nothing else,
    // even when the snapshot's other values have moved on (they wait for
    // their own change kinds).
    (:test)
    function aSecondsOnlyUpdateTouchesNothingElse(logger as Test.Logger) as Boolean {
        var previous = FaceModel.compute(RefreshPlanTest.typical(), config());
        var next = RefreshPlanTest.withClock(9, 15, "Fri", 6, 13, 11);
        next.second = 7;
        next.setValue(METRIC_HEART_RATE, 180);
        next.setValue(METRIC_STEPS, 3110);
        next.battery = 5;
        var expected = FrameEquality.describeFrame(FaceModel.compute(RefreshPlanTest.typical(),
            config()));
        var updated = FaceModel.update(previous, next, config(), CHANGE_SECOND);
        Test.assertEqual("07", updated.seconds);
        updated.seconds = "00";
        Test.assertEqual(expected, FrameEquality.describeFrame(updated));
        return true;
    }

    // The second together with another change (heart rate every second it
    // changes, the clock at every minute) takes the full path, and the
    // seconds still follow the clock.
    (:test)
    function aSecondWithOtherChangesUpdatesTheSecondsToo(logger as Test.Logger) as Boolean {
        var from = RefreshPlanTest.typical();
        from.second = 59;
        var withHeartRate = RefreshPlanTest.withHeartRate(180);
        withHeartRate.second = 7;
        var nextMinute = RefreshPlanTest.withClock(8, 43, "Thu", 5, 12, 11);
        nextMinute.second = 0;
        var cases = [withHeartRate, nextMinute] as Array<Snapshot>;
        var changes = [CHANGE_SECOND | CHANGE_PER_SECOND, CHANGE_SECOND | CHANGE_CLOCK]
            as Array<Number>;
        for (var i = 0; i < cases.size(); i++) {
            var updated = FaceModel.update(FaceModel.compute(from, config()), cases[i], config(),
                changes[i]);
            Test.assertEqualMessage(FrameEquality.describeFrame(updated),
                FrameEquality.describeFrame(FaceModel.compute(cases[i], config())), "case " + i);
        }
        return true;
    }

    // Stories 8, 63: the Always On frame has no seconds and is the same
    // whatever the second; a second change keeps it (the same object).
    (:test)
    function theAodFrameIgnoresTheSeconds(logger as Test.Logger) as Boolean {
        var aod = FaceModel.computeAod(at(7), config());
        Test.assertEqual(FrameEquality.describeAod(aod),
            FrameEquality.describeAod(FaceModel.computeAod(at(8), config())));
        Test.assert(FaceModel.updateAod(aod, at(8), config(), CHANGE_SECOND) == aod);
        return true;
    }

    // Ticket 08's input: the parts that change every second (the seconds,
    // and each field showing a metric read every second) and those that
    // change at most once a minute cover every high-power part, with no
    // overlap, for every accepted face config.
    (:test)
    function everySecondAndEveryMinutePartsSplitTheFrame(logger as Test.Logger) as Boolean {
        var all = RefreshPlanTest.HIGH_POWER_PARTS;
        var fieldParts = [PART_LEFT, PART_CENTER, PART_RIGHT] as Array<Number>;
        var round = [FIELD_LEFT, FIELD_CENTER, FIELD_RIGHT] as Array<Field>;
        var configs = TestConfigs.accepted();
        for (var i = 0; i < configs.size(); i++) {
            var everySecond = FaceModel.everySecondParts(configs[i]);
            var everyMinute = FaceModel.everyMinuteParts(configs[i]);
            Test.assertEqual(all, everySecond | everyMinute);
            Test.assertEqual(0, everySecond & everyMinute);
            // Heart rate is the only metric read every second.
            var expected = PART_SECONDS;
            for (var f = 0; f < round.size(); f++) {
                if (configs[i].metricOf(round[f]) == METRIC_HEART_RATE) {
                    expected |= fieldParts[f];
                }
            }
            Test.assertEqual(expected, everySecond);
        }
        return true;
    }
}
