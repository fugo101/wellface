import Toybox.Lang;
import Toybox.Test;

// The refresh plan: which metrics the face reads and how often (the read
// plan), which frame parts each change kind invalidates, and the update
// entry points that recompute only those parts. Expected read plans come
// from the spec (Refresh plan) and Q36; expected frames always come from a
// fresh full computation that shares no object with the frame passed in.
(:test)
module RefreshPlanTest {
    // A face config in the mint theme with these round-field metrics and
    // steps on the bottom field and the bezel ring, resolved.
    function roundConfig(left as Metric, center as Metric, right as Metric)
            as ResolvedFaceConfig {
        return FaceModel.resolve(new FaceConfig(Themes.MINT, left, center, right, METRIC_STEPS,
            METRIC_STEPS));
    }

    function defaultConfig() as ResolvedFaceConfig {
        return FaceModel.resolve(FaceConfigs.defaultConfig());
    }

    function metricsText(metrics as Array<Metric>) as String {
        var text = "[";
        for (var i = 0; i < metrics.size(); i++) {
            text += (i > 0 ? "," : "") + FrameEquality.metricCode(metrics[i]);
        }
        return text + "]";
    }

    function assertPlan(plan as ReadPlan, everySecond as Array<Metric>,
            everyMinute as Array<Metric>, zones as Boolean) as Void {
        Test.assertEqualMessage(metricsText(plan.everySecond), metricsText(everySecond),
            "every second");
        Test.assertEqualMessage(metricsText(plan.everyMinute), metricsText(everyMinute),
            "every minute");
        Test.assertEqualMessage(plan.zones, zones, "zones");
    }

    // ---- Read plan ----

    (:test)
    function defaultReadPlanIsTodaysReads(logger as Test.Logger) as Boolean {
        // Heart rate every second; stress, Body Battery and steps (with the
        // step goal) once a minute and on wake; zones on wake.
        assertPlan(FaceModel.readPlan(defaultConfig()),
            [METRIC_HEART_RATE] as Array<Metric>,
            [METRIC_STRESS, METRIC_BODY_BATTERY, METRIC_STEPS] as Array<Metric>, true);
        return true;
    }

    (:test)
    function withoutHeartRateNothingIsReadEverySecondAndNoZones(logger as Test.Logger)
            as Boolean {
        assertPlan(FaceModel.readPlan(roundConfig(METRIC_STRESS, METRIC_BODY_BATTERY,
                METRIC_STRESS)),
            [] as Array<Metric>,
            [METRIC_STRESS, METRIC_BODY_BATTERY, METRIC_STEPS] as Array<Metric>, false);
        return true;
    }

    (:test)
    function aMetricShownTwiceIsReadOnce(logger as Test.Logger) as Boolean {
        assertPlan(FaceModel.readPlan(roundConfig(METRIC_HEART_RATE, METRIC_HEART_RATE,
                METRIC_HEART_RATE)),
            [METRIC_HEART_RATE] as Array<Metric>, [METRIC_STEPS] as Array<Metric>, true);
        return true;
    }

    // Over every valid choice of round-field metrics: heart rate is read
    // every second exactly when a field shows it, and the zones are needed
    // exactly when a field draws zone segments (heart rate is the only
    // zone-segment metric).
    (:test)
    function zonesAreNeededExactlyWithZoneSegments(logger as Test.Logger) as Boolean {
        var round = [METRIC_STRESS, METRIC_BODY_BATTERY, METRIC_HEART_RATE] as Array<Metric>;
        for (var l = 0; l < round.size(); l++) {
            for (var c = 0; c < round.size(); c++) {
                for (var r = 0; r < round.size(); r++) {
                    var shown = round[l] == METRIC_HEART_RATE || round[c] == METRIC_HEART_RATE
                        || round[r] == METRIC_HEART_RATE;
                    var plan = FaceModel.readPlan(roundConfig(round[l], round[c], round[r]));
                    var name = metricsText([round[l], round[c], round[r]] as Array<Metric>);
                    Test.assertEqualMessage(plan.zones, shown, name + " zones");
                    Test.assertEqualMessage(metricsText(plan.everySecond),
                        shown ? "[H]" : "[]", name + " every second");
                }
            }
        }
        return true;
    }

    // ---- Invalidation ----

    // Every frame part that is not the AOD frame.
    const HIGH_POWER_PARTS = PART_LEFT | PART_CENTER | PART_RIGHT | PART_BOTTOM
        | PART_BEZEL_RING | PART_TIME | PART_SECONDS | PART_DATE | PART_BATTERY;

    (:test)
    function clockInvalidatesTimeDateAndAod(logger as Test.Logger) as Boolean {
        Test.assertEqual(FaceModel.invalidated(CHANGE_CLOCK, defaultConfig()),
            PART_TIME | PART_DATE | PART_AOD);
        return true;
    }

    // Minute data: the battery bar, the bezel ring, the bottom field and
    // every round field whose metric is read once a minute or draws zone
    // segments, which is every round field with today's metrics. Never the
    // AOD frame.
    (:test)
    function minuteDataInvalidatesEveryFieldAndTheBatteryButNotAod(logger as Test.Logger)
            as Boolean {
        var expected = PART_LEFT | PART_CENTER | PART_RIGHT | PART_BOTTOM | PART_BEZEL_RING
            | PART_BATTERY;
        Test.assertEqual(FaceModel.invalidated(CHANGE_MINUTE_DATA, defaultConfig()), expected);
        Test.assertEqual(FaceModel.invalidated(CHANGE_MINUTE_DATA,
            roundConfig(METRIC_STRESS, METRIC_BODY_BATTERY, METRIC_STRESS)), expected);
        return true;
    }

    // Per-second metrics: only the fields showing one (heart rate).
    (:test)
    function perSecondInvalidatesOnlyTheFieldShowingHeartRate(logger as Test.Logger)
            as Boolean {
        Test.assertEqual(FaceModel.invalidated(CHANGE_PER_SECOND, defaultConfig()), PART_RIGHT);
        Test.assertEqual(FaceModel.invalidated(CHANGE_PER_SECOND,
            roundConfig(METRIC_STRESS, METRIC_HEART_RATE, METRIC_BODY_BATTERY)), PART_CENTER);
        Test.assertEqual(FaceModel.invalidated(CHANGE_PER_SECOND,
            roundConfig(METRIC_HEART_RATE, METRIC_BODY_BATTERY, METRIC_HEART_RATE)),
            PART_LEFT | PART_RIGHT);
        Test.assertEqual(FaceModel.invalidated(CHANGE_PER_SECOND,
            roundConfig(METRIC_STRESS, METRIC_BODY_BATTERY, METRIC_STRESS)), 0);
        return true;
    }

    (:test)
    function changeKindsAddUpAndNoChangeInvalidatesNothing(logger as Test.Logger) as Boolean {
        var config = defaultConfig();
        Test.assertEqual(FaceModel.invalidated(0, config), 0);
        Test.assertEqual(FaceModel.invalidated(CHANGE_CLOCK | CHANGE_PER_SECOND, config),
            PART_TIME | PART_DATE | PART_AOD | PART_RIGHT);
        Test.assertEqual(FaceModel.invalidated(CHANGE_ALL, config), HIGH_POWER_PARTS | PART_AOD);
        return true;
    }

    // ---- Update ----

    // Every value known, no warning, heart rate in zone 2: Thursday 12/11,
    // 08:42.
    function typical() as Snapshot {
        var s = new Snapshot(8, 42);
        s.weekdayName = "Thu";
        s.weekdayNumber = 5;
        s.day = 12;
        s.month = 11;
        s.battery = 64;
        s.setValue(METRIC_STEPS, 1147);
        s.setGoal(METRIC_STEPS, 3110);
        s.setValue(METRIC_BODY_BATTERY, 56);
        s.setValue(METRIC_STRESS, 27);
        s.setValue(METRIC_HEART_RATE, 128);
        s.heartRateZones = [96, 115, 134, 154, 173, 192] as Array<Number>;
        return s;
    }

    function withClock(hour as Number, minute as Number, name as String?,
            weekdayNumber as Number, day as Number, month as Number) as Snapshot {
        var s = typical();
        s.hour = hour;
        s.minute = minute;
        s.weekdayName = name;
        s.weekdayNumber = weekdayNumber;
        s.day = day;
        s.month = month;
        return s;
    }

    // Snapshots that differ from each other only in the clock.
    function clockSnapshots() as Array<Snapshot> {
        return [
            typical(),
            withClock(8, 43, "Thu", 5, 12, 11),
            withClock(23, 59, "Wednesday", 4, 31, 12),
            withClock(0, 0, null, 5, 1, 1),
            withClock(13, 7, "Mittwoch", 4, 9, 3)
        ] as Array<Snapshot>;
    }

    // Snapshots that differ from each other only in the minute data: the
    // battery, stress, Body Battery, steps and the step goal, and the zones
    // (heart rate stays 128).
    function minuteSnapshots() as Array<Snapshot> {
        var missing = typical();
        missing.battery = null;
        missing.setValue(METRIC_STRESS, null);
        missing.setValue(METRIC_BODY_BATTERY, null);
        missing.setValue(METRIC_STEPS, null);
        missing.setGoal(METRIC_STEPS, null);
        missing.heartRateZones = null;
        var warning = typical();
        warning.battery = 5;
        warning.setValue(METRIC_STRESS, 80);
        warning.setValue(METRIC_BODY_BATTERY, 10);
        var reached = typical();
        reached.battery = 18;
        reached.setValue(METRIC_STEPS, 3110);
        var long = typical();
        long.setValue(METRIC_STEPS, 100000);
        long.setGoal(METRIC_STEPS, 15000);
        long.setValue(METRIC_STRESS, -1);
        var lowZones = typical();
        lowZones.heartRateZones = [60, 70, 80, 90, 100, 192] as Array<Number>;
        // The bezel ring: the same lit count as typical (23), one more (24),
        // all 60 lit one step short of the goal, and steps only.
        var sameTicks = typical();
        sameTicks.setValue(METRIC_STEPS, 1150);
        var moreTicks = typical();
        moreTicks.setValue(METRIC_STEPS, 1200);
        var lastStep = typical();
        lastStep.setValue(METRIC_STEPS, 3109);
        return [typical(), missing, warning, reached, long, lowZones, sameTicks, moreTicks,
            lastStep] as Array<Snapshot>;
    }

    function withHeartRate(heartRate as Number?) as Snapshot {
        var s = typical();
        s.setValue(METRIC_HEART_RATE, heartRate);
        return s;
    }

    // Snapshots that differ from each other only in heart rate (zones 2,
    // 0, 5, missing, invalid).
    function perSecondSnapshots() as Array<Snapshot> {
        return [
            typical(), withHeartRate(72), withHeartRate(180), withHeartRate(null),
            withHeartRate(-1), withHeartRate(0)
        ] as Array<Snapshot>;
    }

    // For every ordered pair (a, b) of the snapshots: the frame of a,
    // updated to b with `changes`, equals a fresh full computation of b.
    function assertUpdates(config as ResolvedFaceConfig, snapshots as Array<Snapshot>,
            changes as Number, name as String) as Void {
        for (var a = 0; a < snapshots.size(); a++) {
            for (var b = 0; b < snapshots.size(); b++) {
                var previous = FaceModel.compute(snapshots[a], config);
                var updated = FaceModel.update(previous, snapshots[b], config, changes);
                var expected = FaceModel.compute(snapshots[b], config);
                Test.assertEqualMessage(FrameEquality.describeFrame(updated),
                    FrameEquality.describeFrame(expected), name + " " + a + " -> " + b);
            }
        }
    }

    (:test)
    function clockUpdateEqualsAFullComputation(logger as Test.Logger) as Boolean {
        assertUpdates(defaultConfig(), clockSnapshots(), CHANGE_CLOCK, "clock");
        return true;
    }

    (:test)
    function minuteDataUpdateEqualsAFullComputation(logger as Test.Logger) as Boolean {
        assertUpdates(defaultConfig(), minuteSnapshots(), CHANGE_MINUTE_DATA, "minute data");
        return true;
    }

    (:test)
    function minuteDataUpdateEqualsAFullComputationWithHeartRateElsewhere(
            logger as Test.Logger) as Boolean {
        assertUpdates(roundConfig(METRIC_HEART_RATE, METRIC_STRESS, METRIC_BODY_BATTERY),
            minuteSnapshots(), CHANGE_MINUTE_DATA, "minute data, heart rate left");
        return true;
    }

    (:test)
    function perSecondUpdateEqualsAFullComputation(logger as Test.Logger) as Boolean {
        assertUpdates(defaultConfig(), perSecondSnapshots(), CHANGE_PER_SECOND, "per second");
        assertUpdates(roundConfig(METRIC_STRESS, METRIC_HEART_RATE, METRIC_BODY_BATTERY),
            perSecondSnapshots(), CHANGE_PER_SECOND, "per second, heart rate center");
        return true;
    }

    (:test)
    function updateWithoutAPreviousFrameComputesEverything(logger as Test.Logger) as Boolean {
        var snapshots = minuteSnapshots();
        for (var i = 0; i < snapshots.size(); i++) {
            Test.assertEqualMessage(
                FrameEquality.describeFrame(FaceModel.update(null, snapshots[i],
                    defaultConfig(), 0)),
                FrameEquality.describeFrame(FaceModel.compute(snapshots[i], defaultConfig())),
                "snapshot " + i);
        }
        return true;
    }

    // The lit bezel ticks are recomputed only when their count changes (or
    // the goal is reached): 1.150 steps light the same 23 ticks as 1.147,
    // so the update keeps them; 1.200 light 24, so they are new.
    (:test)
    function litBezelTicksAreRecomputedOnlyWhenTheirCountChanges(logger as Test.Logger)
            as Boolean {
        var config = defaultConfig();
        var previous = FaceModel.compute(typical(), config);
        var ticks = previous.bezelLit;
        var lead = previous.bezelLead;
        var same = typical();
        same.setValue(METRIC_STEPS, 1150);
        var updated = FaceModel.update(previous, same, config, CHANGE_MINUTE_DATA);
        Test.assert(updated.bezelLit == ticks);
        Test.assert(updated.bezelLead == lead);
        var more = typical();
        more.setValue(METRIC_STEPS, 1200);
        updated = FaceModel.update(updated, more, config, CHANGE_MINUTE_DATA);
        Test.assert(updated.bezelLit != ticks);
        Test.assertEqual(23, updated.bezelLit.size());
        return true;
    }

    // Only the parts the change kinds invalidate are recomputed: a heart-rate
    // change alone leaves the time (and the other fields) as they were, even
    // if the snapshot's clock moved on.
    (:test)
    function updateKeepsThePartsNotInvalidated(logger as Test.Logger) as Boolean {
        var config = defaultConfig();
        var previous = FaceModel.compute(typical(), config);
        var next = withClock(8, 43, "Thu", 5, 12, 11);
        next.setValue(METRIC_HEART_RATE, 180);
        next.setValue(METRIC_STRESS, 80);
        var updated = FaceModel.update(previous, next, config, CHANGE_PER_SECOND);
        Test.assertEqual(updated.time, "08:42");
        Test.assertEqual(updated.leftField.number, "27");
        Test.assertEqual(updated.rightField.number, "180");
        Test.assertEqual(updated.rightField.arcs.size(), 5);
        return true;
    }

    // A clock change seen in AOD, then a wake in the same minute: the view
    // passes the union of both, and the frame equals a full computation.
    (:test)
    function clockChangeInAodThenWakeEqualsAFullComputation(logger as Test.Logger)
            as Boolean {
        var config = defaultConfig();
        var previous = FaceModel.compute(typical(), config);
        var woken = withClock(8, 43, "Thu", 5, 12, 11);
        woken.battery = 63;
        woken.setValue(METRIC_STEPS, 1180);
        woken.setValue(METRIC_HEART_RATE, 75);
        var updated = FaceModel.update(previous, woken, config,
            CHANGE_CLOCK | CHANGE_MINUTE_DATA | CHANGE_PER_SECOND);
        Test.assertEqual(FrameEquality.describeFrame(updated),
            FrameEquality.describeFrame(FaceModel.compute(woken, config)));
        return true;
    }

    // ---- AOD update ----

    (:test)
    function minuteDataAndPerSecondChangesKeepTheAodFrame(logger as Test.Logger) as Boolean {
        var config = defaultConfig();
        var previous = FaceModel.computeAod(typical(), config);
        var kept = FaceModel.computeAod(typical(), config);
        var next = withClock(8, 43, "Thu", 5, 12, 11);
        var updated = FaceModel.updateAod(previous, next, config,
            CHANGE_MINUTE_DATA | CHANGE_PER_SECOND);
        Test.assert(updated.equals(previous));
        Test.assertEqual(FrameEquality.describeAod(updated), FrameEquality.describeAod(kept));
        return true;
    }

    (:test)
    function clockUpdateOfTheAodFrameEqualsAFullComputation(logger as Test.Logger)
            as Boolean {
        var config = defaultConfig();
        var snapshots = clockSnapshots();
        for (var a = 0; a < snapshots.size(); a++) {
            for (var b = 0; b < snapshots.size(); b++) {
                var previous = FaceModel.computeAod(snapshots[a], config);
                var updated = FaceModel.updateAod(previous, snapshots[b], config, CHANGE_CLOCK);
                Test.assertEqualMessage(FrameEquality.describeAod(updated),
                    FrameEquality.describeAod(FaceModel.computeAod(snapshots[b], config)),
                    "aod " + a + " -> " + b);
            }
        }
        Test.assertEqual(FrameEquality.describeAod(FaceModel.updateAod(null, typical(), config,
            0)), FrameEquality.describeAod(FaceModel.computeAod(typical(), config)));
        return true;
    }
}
