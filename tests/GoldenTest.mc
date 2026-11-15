import Toybox.Lang;
import Toybox.System;
import Toybox.Test;

// Golden values: what the default face draws today in the mint theme,
// recorded with the FrameEquality descriptions before the settings-ready
// refactor, for a fixed set of snapshots (missing data, each warning level,
// goal reached, zones 0-5, short and long dates with the English fallback
// and the Vietnamese short forms, steps at 100.000, twelve consecutive
// minutes of burn-in offsets), plus the static layer and the long-press
// targets. Every later change must leave them equal.
//
// A failing golden test prints each differing value as
// "GOLDEN <group> <name>=<actual>". Re-record only for an intended change
// to what is drawn: check the printed value, then put it in GoldenValues.
(:test)
module GoldenTest {
    // The wearer's HR_ZONE_SPORT_GENERIC zones as the FR265 returned them
    // (ticket 02): indices 0-4 are the lower bounds of zones 1-5, 5 is max.
    function zones() as Array<Number> {
        return [96, 115, 134, 154, 173, 192] as Array<Number>;
    }

    function fromCodePoints(codePoints as Array<Number>) as String {
        var text = "";
        for (var i = 0; i < codePoints.size(); i++) {
            text += codePoints[i].toChar();
        }
        return text;
    }

    // A full snapshot with every value known and no warning: Thursday
    // 12/11, 08:42, zone 0 (72 bpm is below zone 1).
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
        s.setValue(METRIC_HEART_RATE, 72);
        s.heartRateZones = zones();
        return s;
    }

    function withDate(name as String?, weekdayNumber as Number, day as Number, month as Number)
            as Snapshot {
        var s = typical();
        s.weekdayName = name;
        s.weekdayNumber = weekdayNumber;
        s.day = day;
        s.month = month;
        return s;
    }

    function withSteps(steps as Number?, goal as Number?) as Snapshot {
        var s = typical();
        s.setValue(METRIC_STEPS, steps);
        s.setGoal(METRIC_STEPS, goal);
        return s;
    }

    function withHeartRate(heartRate as Number?, heartRateZones as Array<Number>?) as Snapshot {
        var s = typical();
        s.setValue(METRIC_HEART_RATE, heartRate);
        s.heartRateZones = heartRateZones;
        return s;
    }

    // The fixed snapshot set for the frame, in order.
    const FRAME_CASES = [
        "missing", "typical", "warning1", "warning2", "zones1", "zones2", "zones3", "zones4",
        "zones5", "zonesMissing", "goalReached", "goalReachedLong", "steps100000",
        "fiveDigits", "negativeSteps", "noGoal", "dateLong", "dateTooLong", "dateCyrillic",
        "dateVietnamese", "dateVietnameseSunday", "dateDecember"
    ] as Array<String>;

    function frameCase(name as String) as Snapshot {
        if (name.equals("missing")) {
            return new Snapshot(8, 42);
        }
        if (name.equals("warning1")) {
            var s = typical();
            s.battery = 15;
            s.setValue(METRIC_BODY_BATTERY, 20);
            s.setValue(METRIC_STRESS, 60);
            return s;
        }
        if (name.equals("warning2")) {
            var s = typical();
            s.battery = 5;
            s.setValue(METRIC_BODY_BATTERY, 10);
            s.setValue(METRIC_STRESS, 80);
            return s;
        }
        var zoneRates = { "zones1" => 100, "zones2" => 120, "zones3" => 140, "zones4" => 160,
            "zones5" => 180 } as Dictionary<String, Number>;
        var rate = zoneRates[name];
        if (rate != null) {
            return withHeartRate(rate, zones());
        }
        if (name.equals("zonesMissing")) {
            return withHeartRate(140, null);
        }
        if (name.equals("goalReached")) {
            return withSteps(3110, 3110);
        }
        if (name.equals("goalReachedLong")) {
            return withSteps(12345, 10000);
        }
        if (name.equals("steps100000")) {
            return withSteps(100000, 3110);
        }
        if (name.equals("fiveDigits")) {
            return withSteps(10000, 11111);
        }
        if (name.equals("negativeSteps")) {
            return withSteps(-1, 3110);
        }
        if (name.equals("noGoal")) {
            return withSteps(1147, null);
        }
        return dateCase(name);
    }

    // The date cases, shared by the frame and the AOD frame.
    const DATE_CASES = [
        "typical", "missing", "dateLong", "dateTooLong", "dateCyrillic", "dateVietnamese",
        "dateVietnameseSunday", "dateDecember"
    ] as Array<String>;

    function dateCase(name as String) as Snapshot {
        if (name.equals("missing")) {
            return new Snapshot(8, 42);
        }
        if (name.equals("dateLong")) {
            return withDate("Wednesday", 4, 28, 11);
        }
        if (name.equals("dateTooLong")) {
            return withDate("Wednesday Wednesday", 4, 28, 11);
        }
        if (name.equals("dateCyrillic")) {
            return withDate(fromCodePoints([0x0427, 0x0442]), 5, 12, 11);
        }
        if (name.equals("dateVietnamese")) {
            // "Thứ 5" as the FR265 returns it.
            return withDate(fromCodePoints([0x54, 0x68, 0x1EE9, 0x20, 0x35]), 5, 12, 11);
        }
        if (name.equals("dateVietnameseSunday")) {
            // "Chủ nhật".
            return withDate(fromCodePoints([0x43, 0x68, 0x1EE7, 0x20, 0x6E, 0x68, 0x1EAD, 0x74]),
                1, 15, 11);
        }
        if (name.equals("dateDecember")) {
            return withDate("Sat", 7, 31, 12);
        }
        return typical();
    }

    // Twelve consecutive minutes, across midnight, for every burn-in offset.
    function aodMinuteCase(i as Number) as Snapshot {
        var s = typical();
        var minuteOfDay = (23 * 60 + 54 + i) % (24 * 60);
        s.hour = minuteOfDay / 60;
        s.minute = minuteOfDay % 60;
        return s;
    }

    const AOD_MINUTES = 12;

    // The long-press targets on a grid every 8 px from (4, 4), one row per y,
    // run-length encoded: "<target>*<count>" per run, runs joined by ",",
    // rows by "/".
    const TARGET_STEP = 8;

    function describeTargetRow(y as Number) as String {
        var row = "";
        var run = "";
        var count = 0;
        for (var x = TARGET_STEP / 2; x < 416; x += TARGET_STEP) {
            var code = FrameEquality.describeTarget(FaceModel.longPressTarget(x, y, config()));
            if (code.equals(run)) {
                count++;
                continue;
            }
            if (count > 0) {
                row += (row.length() > 0 ? "," : "") + run + "*" + count;
            }
            run = code;
            count = 1;
        }
        return row + (row.length() > 0 ? "," : "") + run + "*" + count;
    }

    // Compares and prints the actual value when it differs (or there is no
    // golden value yet). Returns true when equal.
    function matches(group as String, name as String, actual as String,
            expected as String?) as Boolean {
        if (expected != null && expected.equals(actual)) {
            return true;
        }
        System.println("GOLDEN " + group + " " + name + "=" + actual);
        return false;
    }

    // The built-in face config (today's mapping) with the mint theme.
    function config() as ResolvedFaceConfig {
        return TestConfigs.mintDefault();
    }

    (:test)
    function framesMatchTheGoldenValues(logger as Test.Logger) as Boolean {
        var failed = 0;
        for (var i = 0; i < FRAME_CASES.size(); i++) {
            var name = FRAME_CASES[i];
            var actual = FrameEquality.describeFrame(
                FaceModel.compute(frameCase(name), config()));
            if (!matches("frame", name, actual, GoldenValues.FRAMES[name])) {
                failed++;
            }
        }
        Test.assertEqual(0, failed);
        return true;
    }

    (:test)
    function aodFramesMatchTheGoldenValues(logger as Test.Logger) as Boolean {
        var failed = 0;
        for (var i = 0; i < DATE_CASES.size(); i++) {
            var name = DATE_CASES[i];
            var actual = FrameEquality.describeAod(FaceModel.computeAod(dateCase(name), config()));
            if (!matches("aod", name, actual, GoldenValues.AOD_FRAMES[name])) {
                failed++;
            }
        }
        for (var i = 0; i < AOD_MINUTES; i++) {
            var name = "minute" + i;
            var actual = FrameEquality.describeAod(FaceModel.computeAod(aodMinuteCase(i), config()));
            if (!matches("aod", name, actual, GoldenValues.AOD_FRAMES[name])) {
                failed++;
            }
        }
        Test.assertEqual(0, failed);
        return true;
    }

    (:test)
    function staticLayerMatchesTheGoldenValue(logger as Test.Logger) as Boolean {
        var layer = FrameEquality.describeLayer(FaceModel.staticLayer(config()));
        Test.assert(matches("layer", "mint", layer, GoldenValues.STATIC_LAYER));
        return true;
    }

    (:test)
    function longPressTargetsMatchTheGoldenValue(logger as Test.Logger) as Boolean {
        var rows = "";
        for (var y = TARGET_STEP / 2; y < 416; y += TARGET_STEP) {
            rows += (rows.length() > 0 ? "/" : "") + describeTargetRow(y);
        }
        Test.assert(matches("targets", "grid", rows, GoldenValues.LONG_PRESS_TARGETS));
        return true;
    }

    // --- Completeness: every member counts in the equality helpers ---------

    // The reference values: everything known, so no member is at a default.
    function referenceFrame() as Frame {
        return FaceModel.compute(withHeartRate(140, zones()), config());
    }

    function referenceAod() as AodFrame {
        return FaceModel.computeAod(typical(), config());
    }

    function otherRect() as RoundedRect {
        return new RoundedRect(1, 2, 3, 4, 1, 0x123456);
    }

    function otherArc() as Arc {
        return new Arc(1, 2, 3, 4, 5, 6, 7, 0x123456);
    }

    function otherCircle() as Circle {
        return new Circle(1, 2, 3, 0x123456);
    }

    function otherFont(font as FontId) as FontId {
        return font == FONT_NUMBER_18 ? FONT_NUMBER_22 : FONT_NUMBER_18;
    }

    // Changes member i of a frame; false when there is no member i.
    function changeFrame(f as Frame, i as Number) as Boolean {
        switch (i) {
            case 0: f.time += "0"; break;
            case 1: f.timeWidth++; break;
            case 2: f.timeX++; break;
            case 3: f.timeY++; break;
            case 4: f.timeColor++; break;
            case 5: f.seconds += "0"; break;
            case 6: f.secondsX++; break;
            case 7: f.secondsY++; break;
            case 8: f.secondsColor++; break;
            case 9: f.date += "0"; break;
            case 10: f.dateWidth++; break;
            case 11: f.dateX++; break;
            case 12: f.dateY++; break;
            case 13: f.weekday += "0"; break;
            case 14: f.weekdayColor++; break;
            case 15: f.dayMonth += "0"; break;
            case 16: f.dayMonthX++; break;
            case 17: f.dayMonthColor++; break;
            case 18: f.datePill = otherRect(); break;
            case 19: f.batteryLit = [] as Array<Arc>; break;
            case 20: f.bezelLit = [] as Array<Line>; break;
            case 21: f.bezelLead = null; break;
            case 22: f.bottomGoalReached = !f.bottomGoalReached; break;
            case 23: f.bottomField.number += "0"; break;
            case 24: f.leftField.number += "0"; break;
            case 25: f.centerField.number += "0"; break;
            case 26: f.rightField.number += "0"; break;
            default: return false;
        }
        return true;
    }

    function changeField(f as FieldFrame, i as Number) as Boolean {
        switch (i) {
            case 0: f.arcs = [] as Array<Arc>; break;
            case 1: f.caps = [] as Array<Circle>; break;
            case 2: f.dot = f.dot == null ? otherCircle() : null; break;
            case 3: f.icon += "0"; break;
            case 4: f.iconX++; break;
            case 5: f.iconY++; break;
            case 6: f.iconColor++; break;
            case 7: f.number += "0"; break;
            case 8: f.numberColor++; break;
            case 9: f.numberFont = otherFont(f.numberFont); break;
            case 10: f.numberWidth++; break;
            case 11: f.numberX++; break;
            case 12: f.numberY++; break;
            default: return false;
        }
        return true;
    }

    function changeBottomField(f as BottomFieldFrame, i as Number) as Boolean {
        switch (i) {
            case 0: f.pill = otherRect(); break;
            case 1: f.icon += "0"; break;
            case 2: f.iconX++; break;
            case 3: f.iconY++; break;
            case 4: f.iconColor++; break;
            case 5: f.number += "0"; break;
            case 6: f.numberFont = otherFont(f.numberFont); break;
            case 7: f.numberWidth++; break;
            case 8: f.numberX++; break;
            case 9: f.numberY++; break;
            case 10: f.numberColor++; break;
            case 11: f.goal += "0"; break;
            case 12: f.goalX++; break;
            case 13: f.goalY++; break;
            case 14: f.goalColor++; break;
            default: return false;
        }
        return true;
    }

    function changeAod(f as AodFrame, i as Number) as Boolean {
        switch (i) {
            case 0: f.time += "0"; break;
            case 1: f.timeX++; break;
            case 2: f.timeY++; break;
            case 3: f.timeColor++; break;
            case 4: f.date += "0"; break;
            case 5: f.dateX++; break;
            case 6: f.dateY++; break;
            case 7: f.dateColor++; break;
            case 8: f.datePill = otherRect(); break;
            case 9: f.datePillInner = otherRect(); break;
            case 10: f.offsetX++; break;
            case 11: f.offsetY++; break;
            default: return false;
        }
        return true;
    }

    function changeLayer(l as StaticLayer, i as Number) as Boolean {
        switch (i) {
            case 0: l.backgroundColor++; break;
            case 1: l.edgeMask = otherArc(); break;
            case 2: l.bezelTicks = [] as Array<Line>; break;
            case 3: l.timeBandRim = otherRect(); break;
            case 4: l.fieldRims = [] as Array<Circle>; break;
            case 5: l.bottomFieldRim = otherRect(); break;
            case 6: l.timeBandWell = otherRect(); break;
            case 7: l.timeBand = otherRect(); break;
            case 8: l.batteryWell = otherArc(); break;
            case 9: l.batteryCaps = [] as Array<Circle>; break;
            case 10: l.batteryTrack = [] as Array<Arc>; break;
            case 11: l.fieldWells = [] as Array<Circle>; break;
            case 12: l.fieldTracks = [] as Array<Arc>; break;
            case 13: l.fieldTrackCaps = [] as Array<Circle>; break;
            default: return false;
        }
        return true;
    }

    function changeArc(a as Arc, i as Number) as Boolean {
        switch (i) {
            case 0: a.x++; break;
            case 1: a.y++; break;
            case 2: a.radius++; break;
            case 3: a.pen++; break;
            case 4: a.start++; break;
            case 5: a.end++; break;
            case 6: a.sweep++; break;
            case 7: a.color++; break;
            default: return false;
        }
        return true;
    }

    function changeRect(r as RoundedRect, i as Number) as Boolean {
        switch (i) {
            case 0: r.x++; break;
            case 1: r.y++; break;
            case 2: r.width++; break;
            case 3: r.height++; break;
            case 4: r.radius++; break;
            case 5: r.color++; break;
            default: return false;
        }
        return true;
    }

    function changeCircle(c as Circle, i as Number) as Boolean {
        switch (i) {
            case 0: c.x++; break;
            case 1: c.y++; break;
            case 2: c.radius++; break;
            case 3: c.color++; break;
            default: return false;
        }
        return true;
    }

    function changeLine(l as Line, i as Number) as Boolean {
        switch (i) {
            case 0: l.x1++; break;
            case 1: l.y1++; break;
            case 2: l.x2++; break;
            case 3: l.y2++; break;
            case 4: l.pen++; break;
            case 5: l.color++; break;
            default: return false;
        }
        return true;
    }

    function changeTarget(t as LongPressTarget, i as Number) as Boolean {
        switch (i) {
            case 0: t.field = t.field == FIELD_LEFT ? FIELD_RIGHT : FIELD_LEFT; break;
            case 1: t.metric = t.metric == METRIC_STRESS ? METRIC_STEPS : METRIC_STRESS; break;
            default: return false;
        }
        return true;
    }

    // Member counts. A new member needs a line in its FrameEquality
    // description, a case in its change function and a count here. Monkey C
    // has no reflection, so a member added to a class without a case here
    // goes unnoticed.
    const FRAME_MEMBERS = 27;
    const FIELD_MEMBERS = 13;
    const BOTTOM_FIELD_MEMBERS = 15;
    const AOD_MEMBERS = 12;
    const LAYER_MEMBERS = 14;
    const ARC_MEMBERS = 8;
    const RECT_MEMBERS = 6;
    const CIRCLE_MEMBERS = 4;
    const LINE_MEMBERS = 6;
    const TARGET_MEMBERS = 2;

    (:test)
    function equalFramesAreEqual(logger as Test.Logger) as Boolean {
        Test.assert(FrameEquality.framesEqual(referenceFrame(), referenceFrame()));
        Test.assert(FrameEquality.aodFramesEqual(referenceAod(), referenceAod()));
        Test.assert(FrameEquality.layersEqual(FaceModel.staticLayer(config()),
            FaceModel.staticLayer(config())));
        Test.assert(FrameEquality.targetsEqual(FaceModel.longPressTarget(208, 256, config()),
            FaceModel.longPressTarget(208, 256, config())));
        Test.assert(FrameEquality.targetsEqual(null, null));
        Test.assert(!FrameEquality.targetsEqual(FaceModel.longPressTarget(208, 256, config()),
            null));
        return true;
    }

    (:test)
    function everyFrameMemberIsCompared(logger as Test.Logger) as Boolean {
        var i = 0;
        while (true) {
            var changed = referenceFrame();
            if (!changeFrame(changed, i)) {
                break;
            }
            Test.assertMessage(!FrameEquality.framesEqual(referenceFrame(), changed),
                "frame member " + i + " is not compared");
            i++;
        }
        Test.assertEqual(FRAME_MEMBERS, i);
        return true;
    }

    (:test)
    function everyFieldMemberIsCompared(logger as Test.Logger) as Boolean {
        var i = 0;
        while (true) {
            var changed = referenceFrame();
            if (!changeField(changed.rightField, i)) {
                break;
            }
            Test.assertMessage(!FrameEquality.framesEqual(referenceFrame(), changed),
                "field member " + i + " is not compared");
            i++;
        }
        Test.assertEqual(FIELD_MEMBERS, i);
        return true;
    }

    (:test)
    function everyBottomFieldMemberIsCompared(logger as Test.Logger) as Boolean {
        var i = 0;
        while (true) {
            var changed = referenceFrame();
            if (!changeBottomField(changed.bottomField, i)) {
                break;
            }
            Test.assertMessage(!FrameEquality.framesEqual(referenceFrame(), changed),
                "bottom field member " + i + " is not compared");
            i++;
        }
        Test.assertEqual(BOTTOM_FIELD_MEMBERS, i);
        return true;
    }

    (:test)
    function everyAodMemberIsCompared(logger as Test.Logger) as Boolean {
        var i = 0;
        while (true) {
            var changed = referenceAod();
            if (!changeAod(changed, i)) {
                break;
            }
            Test.assertMessage(!FrameEquality.aodFramesEqual(referenceAod(), changed),
                "AOD member " + i + " is not compared");
            i++;
        }
        Test.assertEqual(AOD_MEMBERS, i);
        return true;
    }

    (:test)
    function everyStaticLayerMemberIsCompared(logger as Test.Logger) as Boolean {
        var i = 0;
        while (true) {
            var changed = FaceModel.staticLayer(config());
            if (!changeLayer(changed, i)) {
                break;
            }
            Test.assertMessage(!FrameEquality.layersEqual(
                FaceModel.staticLayer(config()), changed),
                "static layer member " + i + " is not compared");
            i++;
        }
        Test.assertEqual(LAYER_MEMBERS, i);
        return true;
    }

    // Arcs, rounded rects, circles and lines through a frame, targets on
    // their own.
    (:test)
    function everyNestedMemberIsCompared(logger as Test.Logger) as Boolean {
        var i = 0;
        while (true) {
            var changed = referenceFrame();
            if (!changeArc(changed.batteryLit[0], i)) {
                break;
            }
            Test.assertMessage(!FrameEquality.framesEqual(referenceFrame(), changed),
                "arc member " + i + " is not compared");
            i++;
        }
        Test.assertEqual(ARC_MEMBERS, i);

        i = 0;
        while (true) {
            var changed = referenceFrame();
            if (!changeRect(changed.datePill, i)) {
                break;
            }
            Test.assertMessage(!FrameEquality.framesEqual(referenceFrame(), changed),
                "rounded rect member " + i + " is not compared");
            i++;
        }
        Test.assertEqual(RECT_MEMBERS, i);

        i = 0;
        while (true) {
            var changed = referenceFrame();
            if (!changeCircle(changed.centerField.caps[0], i)) {
                break;
            }
            Test.assertMessage(!FrameEquality.framesEqual(referenceFrame(), changed),
                "circle member " + i + " is not compared");
            i++;
        }
        Test.assertEqual(CIRCLE_MEMBERS, i);

        i = 0;
        while (true) {
            var changed = referenceFrame();
            var lead = changed.bezelLead;
            Test.assert(lead != null);
            if (!changeLine(lead as Line, i)) {
                break;
            }
            Test.assertMessage(!FrameEquality.framesEqual(referenceFrame(), changed),
                "line member " + i + " is not compared");
            i++;
        }
        Test.assertEqual(LINE_MEMBERS, i);

        i = 0;
        while (true) {
            var changed = FaceModel.longPressTarget(88, 246, config()) as LongPressTarget;
            if (!changeTarget(changed, i)) {
                break;
            }
            Test.assertMessage(!FrameEquality.targetsEqual(
                FaceModel.longPressTarget(88, 246, config()), changed),
                "long-press target member " + i + " is not compared");
            i++;
        }
        Test.assertEqual(TARGET_MEMBERS, i);
        return true;
    }
}
