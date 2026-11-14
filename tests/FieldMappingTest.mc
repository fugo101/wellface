import Toybox.Lang;
import Toybox.Test;

// A metric moved to another valid field brings its whole look with it (track
// kind, lit arcs, zone colors, icon, number text, warning colors, long-press
// page), while the field keeps its own geometry (well, rim, ring radius and
// pen, icon slot, number slot, number size). Expected values are the design's
// coordinates and the mint theme's colors.
(:test)
module FieldMappingTest {
    const WHITE = 0xFFFFFF;
    const GRAY = 0x8C8C8C;
    const ACCENT = 0x8EE3B8;
    const ORANGE = 0xFF8A3D;
    const RED = 0xFF4D4D;
    const TRACK = 0x2E3330;
    const ZONE_COLORS = [0xB4B4B4, 0x4DA6FF, 0x4CD964, 0xFF8A3D, 0xFF4D4D] as Array<Number>;

    // A face config in the mint theme with these metrics, resolved.
    function configOf(left as Metric, center as Metric, right as Metric, bottom as Metric,
            bezelRing as Metric) as ResolvedFaceConfig {
        return FaceModel.resolve(new FaceConfig("mint", left, center, right, bottom, bezelRing));
    }

    // Heart rate and Body Battery swapped: heart rate in the center, Body
    // Battery on the right.
    function swapped() as ResolvedFaceConfig {
        return configOf(METRIC_STRESS, METRIC_HEART_RATE, METRIC_BODY_BATTERY,
            METRIC_STEPS, METRIC_STEPS);
    }

    // Heart rate on the left, stress on the right.
    function heartRateLeft() as ResolvedFaceConfig {
        return configOf(METRIC_HEART_RATE, METRIC_BODY_BATTERY, METRIC_STRESS,
            METRIC_STEPS, METRIC_STEPS);
    }

    // The wearer's zones (ticket 02 of the MVP): lower bounds of zones 1-5, then max.
    function zones() as Array<Number> {
        return [96, 115, 134, 154, 173, 192] as Array<Number>;
    }

    function snapshotWith(metric as Metric, value as Number?) as Snapshot {
        var s = new Snapshot(8, 42);
        s.heartRateZones = zones();
        s.setValue(metric, value);
        return s;
    }

    function frameWith(config as ResolvedFaceConfig, metric as Metric, value as Number?)
            as Frame {
        return FaceModel.compute(snapshotWith(metric, value), config);
    }

    function layerOf(config as ResolvedFaceConfig) as StaticLayer {
        return FaceModel.staticLayer(config);
    }

    // The static layer's tracks centered on (x, y), in order.
    function tracksAt(layer as StaticLayer, x as Number, y as Number) as Array<Arc> {
        var found = [] as Array<Arc>;
        for (var i = 0; i < layer.fieldTracks.size(); i++) {
            var track = layer.fieldTracks[i];
            if (track.x == x && track.y == y) {
                found.add(track);
            }
        }
        return found;
    }

    // The static layer's circle of this radius centered on (x, y), asserted
    // to be there once.
    function assertCircleAt(circles as Array<Circle>, x as Number, y as Number,
            radius as Number, color as Number) as Void {
        var count = 0;
        for (var i = 0; i < circles.size(); i++) {
            var c = circles[i];
            if (c.x == x && c.y == y && c.radius == radius && c.color == color) {
                count++;
            }
        }
        Test.assertMessage(count == 1, "no circle r " + radius + " at " + x + ", " + y);
    }

    // Wells and rims stay with the position whatever the mapping (Q39).
    function assertWellsAndRims(layer as StaticLayer) as Void {
        Test.assertEqual(3, layer.fieldWells.size());
        Test.assertEqual(3, layer.fieldRims.size());
        assertCircleAt(layer.fieldWells, 88, 246, 44, 0x000000);
        assertCircleAt(layer.fieldWells, 208, 256, 66, 0x000000);
        assertCircleAt(layer.fieldWells, 328, 246, 44, 0x000000);
        assertCircleAt(layer.fieldRims, 88, 246, 46, 0x446D58);
        assertCircleAt(layer.fieldRims, 208, 256, 68, 0x446D58);
        assertCircleAt(layer.fieldRims, 328, 246, 46, 0x446D58);
    }

    // `count` lit zone segments on the ring (x, y, radius, pen), each in its
    // zone's color; segment 0 spans ciq 86 clockwise to 22.
    function assertZoneSegments(arcs as Array<Arc>, count as Number, x as Number, y as Number,
            radius as Number, pen as Number, color as Number?) as Void {
        Test.assertEqual(count, arcs.size());
        for (var i = 0; i < arcs.size(); i++) {
            Test.assertEqual(x, arcs[i].x);
            Test.assertEqual(y, arcs[i].y);
            Test.assertEqual(radius, arcs[i].radius);
            Test.assertEqual(pen, arcs[i].pen);
            Test.assertEqual(64, arcs[i].sweep);
            Test.assertEqual(color != null ? color : ZONE_COLORS[i], arcs[i].color);
        }
        if (count > 0) {
            Test.assertEqual(86, arcs[0].start);
            Test.assertEqual(22, arcs[0].end);
        }
    }

    // One gauge arc from 12 o'clock on the ring (x, y, radius, pen).
    function assertGauge(arcs as Array<Arc>, sweep as Number, x as Number, y as Number,
            radius as Number, pen as Number, color as Number) as Void {
        Test.assertEqual(1, arcs.size());
        var gauge = arcs[0];
        Test.assertEqual(sweep, gauge.sweep);
        Test.assertEqual(90, gauge.start);
        Test.assertEqual(x, gauge.x);
        Test.assertEqual(y, gauge.y);
        Test.assertEqual(radius, gauge.radius);
        Test.assertEqual(pen, gauge.pen);
        Test.assertEqual(color, gauge.color);
    }

    function assertTarget(config as ResolvedFaceConfig, x as Number, y as Number,
            field as Field, metric as Metric) as Void {
        var target = FaceModel.longPressTarget(x, y, config);
        Test.assert(target != null);
        Test.assertEqual(field, (target as LongPressTarget).field);
        Test.assertEqual(metric, (target as LongPressTarget).metric);
    }

    // The number is centered on the field's x (to within half a pixel) and
    // its 26 px digits on y 260 (baseline 269), as on the side fields today.
    function assertSideNumberSlot(field as FieldFrame, x as Number) as Void {
        Test.assertEqual(FONT_NUMBER_26, field.numberFont);
        var twiceCenter = 2 * field.numberX + field.numberWidth;
        Test.assert(twiceCenter >= 2 * x - 1 && twiceCenter <= 2 * x + 1);
        Test.assertEqual(269, field.numberY + FontCatalog.entry(FONT_NUMBER_26).base);
    }

    function iconText(codePoint as Number) as String {
        return codePoint.toChar().toString();
    }

    // Story 8: heart rate in the center shows its zone segments at the
    // center field's ring (208, 256, r 56, pen 9) in the zone colors, the
    // heart at the center's icon slot and its number at 48 px.
    (:test)
    function heartRateInTheCenterKeepsItsLookAtTheCenterGeometry(logger as Test.Logger)
            as Boolean {
        var field = frameWith(swapped(), METRIC_HEART_RATE, 140).centerField;
        assertZoneSegments(field.arcs, 3, 208, 256, 56, 9, null);
        Test.assertEqual(iconText(0xE002), field.icon);
        Test.assertEqual(196, field.iconX);
        Test.assertEqual(213, field.iconY);
        Test.assertEqual(GRAY, field.iconColor);
        Test.assertEqual("140", field.number);
        Test.assertEqual(WHITE, field.numberColor);
        Test.assertEqual(FONT_NUMBER_48, field.numberFont);
        var twiceCenter = 2 * field.numberX + field.numberWidth;
        Test.assert(twiceCenter >= 415 && twiceCenter <= 417);
        // Digits centered on y 268: the 48 px baseline sits on 285.
        Test.assertEqual(285, field.numberY + FontCatalog.entry(FONT_NUMBER_48).base);
        return true;
    }

    // Story 11: Body Battery on the right keeps its gauge and its red
    // warning, at the right field's ring (328, 246, r 35, pen 6), icon slot
    // and 26 px number.
    (:test)
    function bodyBatteryOnTheRightKeepsItsGaugeAndWarning(logger as Test.Logger) as Boolean {
        var field = frameWith(swapped(), METRIC_BODY_BATTERY, 10).rightField;
        assertGauge(field.arcs, 36, 328, 246, 35, 6, RED);
        Test.assertEqual(iconText(0xE000), field.icon);
        Test.assertEqual(316, field.iconX);
        Test.assertEqual(216, field.iconY);
        Test.assertEqual(RED, field.iconColor);
        Test.assertEqual("10", field.number);
        Test.assertEqual(RED, field.numberColor);
        assertSideNumberSlot(field, 328);
        Test.assertEqual(ORANGE, frameWith(swapped(), METRIC_BODY_BATTERY, 20).rightField
            .numberColor);
        return true;
    }

    // Story 13: the static track follows the metric: five unlit segments
    // under heart rate in the center, a full ring under Body Battery on the
    // right. Wells and rims stay.
    (:test)
    function swappedTracksFollowTheMetric(logger as Test.Logger) as Boolean {
        var layer = layerOf(swapped());
        var center = tracksAt(layer, 208, 256);
        assertZoneSegments(center, 5, 208, 256, 56, 9, TRACK);
        var right = tracksAt(layer, 328, 246);
        Test.assertEqual(1, right.size());
        Test.assertEqual(360, right[0].sweep);
        Test.assertEqual(35, right[0].radius);
        Test.assertEqual(6, right[0].pen);
        Test.assertEqual(TRACK, right[0].color);
        assertWellsAndRims(layer);
        return true;
    }

    // Story 12: a hold opens the page of the metric now shown there.
    (:test)
    function swappedLongPressFollowsTheMetric(logger as Test.Logger) as Boolean {
        assertTarget(swapped(), 208, 256, FIELD_CENTER, METRIC_HEART_RATE);
        assertTarget(swapped(), 328, 246, FIELD_RIGHT, METRIC_BODY_BATTERY);
        assertTarget(swapped(), 88, 246, FIELD_LEFT, METRIC_STRESS);
        assertTarget(swapped(), 208, 350, FIELD_BOTTOM, METRIC_STEPS);
        assertTarget(swapped(), 208, 6, FIELD_BEZEL_RING, METRIC_STEPS);
        return true;
    }

    // Story 9: heart rate on the left looks as it does on the right today,
    // at the left field's ring (88, 246) and icon slot (76, 216).
    (:test)
    function heartRateOnTheLeftLooksAsOnTheRight(logger as Test.Logger) as Boolean {
        var field = frameWith(heartRateLeft(), METRIC_HEART_RATE, 180).leftField;
        assertZoneSegments(field.arcs, 5, 88, 246, 35, 6, null);
        Test.assertEqual(iconText(0xE002), field.icon);
        Test.assertEqual(76, field.iconX);
        Test.assertEqual(216, field.iconY);
        Test.assertEqual(GRAY, field.iconColor);
        Test.assertEqual("180", field.number);
        Test.assertEqual(WHITE, field.numberColor);
        assertSideNumberSlot(field, 88);
        return true;
    }

    // Story 10: stress on the right keeps its orange and red warnings.
    (:test)
    function stressOnTheRightKeepsItsWarnings(logger as Test.Logger) as Boolean {
        var red = frameWith(heartRateLeft(), METRIC_STRESS, 80).rightField;
        assertGauge(red.arcs, 288, 328, 246, 35, 6, RED);
        Test.assertEqual(iconText(0xE001), red.icon);
        Test.assertEqual(316, red.iconX);
        Test.assertEqual(RED, red.iconColor);
        Test.assertEqual(RED, red.numberColor);
        assertSideNumberSlot(red, 328);
        var orange = frameWith(heartRateLeft(), METRIC_STRESS, 60).rightField;
        assertGauge(orange.arcs, 216, 328, 246, 35, 6, ORANGE);
        Test.assertEqual(ORANGE, orange.numberColor);
        var calm = frameWith(heartRateLeft(), METRIC_STRESS, 27).rightField;
        assertGauge(calm.arcs, 97, 328, 246, 35, 6, ACCENT);
        Test.assertEqual(WHITE, calm.numberColor);
        return true;
    }

    (:test)
    function heartRateLeftTracksAndLongPressFollowTheMetric(logger as Test.Logger) as Boolean {
        var layer = layerOf(heartRateLeft());
        assertZoneSegments(tracksAt(layer, 88, 246), 5, 88, 246, 35, 6, TRACK);
        var right = tracksAt(layer, 328, 246);
        Test.assertEqual(1, right.size());
        Test.assertEqual(360, right[0].sweep);
        Test.assertEqual(1, tracksAt(layer, 208, 256).size());
        assertWellsAndRims(layer);
        assertTarget(heartRateLeft(), 88, 246, FIELD_LEFT, METRIC_HEART_RATE);
        assertTarget(heartRateLeft(), 328, 246, FIELD_RIGHT, METRIC_STRESS);
        assertTarget(heartRateLeft(), 208, 256, FIELD_CENTER, METRIC_BODY_BATTERY);
        return true;
    }

    // Story 35: a negative reading of any metric shows as missing in every
    // field kind it can go to: "--" in gray with no lit arc in each round
    // field, and an empty bezel ring, no head dot, no goal reached and "--"
    // in the bottom field for a goal metric.
    (:test)
    function negativeReadingShowsAsMissingInEveryFieldKind(logger as Test.Logger) as Boolean {
        var round = [METRIC_STRESS, METRIC_BODY_BATTERY, METRIC_HEART_RATE] as Array<Metric>;
        for (var i = 0; i < round.size(); i++) {
            var m = round[i];
            var everywhere = configOf(m, m, m, METRIC_STEPS, METRIC_STEPS);
            var frame = frameWith(everywhere, m, -1);
            var fields = [frame.leftField, frame.centerField, frame.rightField]
                as Array<FieldFrame>;
            for (var f = 0; f < fields.size(); f++) {
                Test.assertEqual("--", fields[f].number);
                Test.assertEqual(GRAY, fields[f].numberColor);
                Test.assertEqual(GRAY, fields[f].iconColor);
                Test.assertEqual(0, fields[f].arcs.size());
            }
        }

        var s = new Snapshot(8, 42);
        s.setValue(METRIC_STEPS, -5);
        s.setGoal(METRIC_STEPS, 3110);
        var goalFrame = FaceModel.compute(s, FaceModel.resolve(FaceConfigs.defaultConfig()));
        Test.assertEqual("--", goalFrame.bottomField.number);
        Test.assertEqual(GRAY, goalFrame.bottomField.numberColor);
        Test.assertEqual("/ 3.110", goalFrame.bottomField.goal);
        Test.assertEqual(0, goalFrame.bezelProgress.sweep);
        Test.assert(goalFrame.bezelHead == null);
        Test.assert(!goalFrame.bottomGoalReached);
        return true;
    }

    // A negative goal is no goal: no "/ goal", no progress.
    (:test)
    function negativeGoalShowsAsNoGoal(logger as Test.Logger) as Boolean {
        var s = new Snapshot(8, 42);
        s.setValue(METRIC_STEPS, 1147);
        s.setGoal(METRIC_STEPS, -3110);
        var frame = FaceModel.compute(s, FaceModel.resolve(FaceConfigs.defaultConfig()));
        Test.assertEqual("1.147", frame.bottomField.number);
        Test.assertEqual("", frame.bottomField.goal);
        Test.assertEqual(0, frame.bezelProgress.sweep);
        Test.assert(frame.bezelHead == null);
        return true;
    }

    // Q40 (stories 15-17): a round field accepts the metrics drawn as a gauge
    // or as zone segments (stress, Body Battery, heart rate); the bottom
    // field and the bezel ring accept goal metrics only (steps).
    (:test)
    function fieldKindsAcceptOnlyTheStylesTheyCanDraw(logger as Test.Logger) as Boolean {
        var fields = [FIELD_LEFT, FIELD_CENTER, FIELD_RIGHT, FIELD_BOTTOM, FIELD_BEZEL_RING]
            as Array<Field>;
        var round = [true, true, true, false] as Array<Boolean>;
        var goal = [false, false, false, true] as Array<Boolean>;
        // In Metric order: stress, Body Battery, heart rate, steps.
        var metrics = [METRIC_STRESS, METRIC_BODY_BATTERY, METRIC_HEART_RATE, METRIC_STEPS]
            as Array<Metric>;
        for (var f = 0; f < fields.size(); f++) {
            var expected = f < 3 ? round : goal;
            for (var m = 0; m < metrics.size(); m++) {
                Test.assertMessage(expected[m] == FaceModel.accepts(fields[f], metrics[m]),
                    "field " + fields[f] + ", metric " + metrics[m]);
            }
        }
        return true;
    }
}
