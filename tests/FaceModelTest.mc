import Toybox.Lang;
import Toybox.Test;

// Every declaration here is (:test) so no test code reaches a release build.
(:test)
module FaceModelTest {

    // Helpers stay unannotated: the (:test) module keeps them out of release builds.
    function frameAt(hour as Number, minute as Number) as Frame {
        return FaceModel.compute(new Snapshot(hour, minute), Themes.mint());
    }

    function mintLayer() as StaticLayer {
        return FaceModel.staticLayer(Themes.mint());
    }

    function frameWithBattery(battery as Number?) as Frame {
        var snapshot = new Snapshot(8, 42);
        snapshot.battery = battery;
        return FaceModel.compute(snapshot, Themes.mint());
    }

    // weekdayNumber: 1 = Sunday ... 7 = Saturday (FORMAT_SHORT).
    function snapshotOnDate(weekdayName as String?, weekdayNumber as Number, day as Number)
            as Snapshot {
        var snapshot = new Snapshot(8, 42);
        snapshot.weekdayName = weekdayName;
        snapshot.weekdayNumber = weekdayNumber;
        snapshot.day = day;
        return snapshot;
    }

    function frameOnDate(weekdayName as String?, weekdayNumber as Number, day as Number) as Frame {
        return FaceModel.compute(snapshotOnDate(weekdayName, weekdayNumber, day), Themes.mint());
    }

    function dateOf(weekdayName as String?, weekdayNumber as Number, day as Number) as String {
        return frameOnDate(weekdayName, weekdayNumber, day).date;
    }

    // A string spelled out code point by code point, so tests state exactly
    // what the watch returns (precomposed or combining).
    function fromCodePoints(codePoints as Array<Number>) as String {
        var text = "";
        for (var i = 0; i < codePoints.size(); i++) {
            text += codePoints[i].toChar();
        }
        return text;
    }

    // A box from x, width wide, centered on x 208 to within half a pixel.
    function assertCenteredOn208(x as Number, width as Number) as Void {
        var twiceCenter = 2 * x + width;
        Test.assert(twiceCenter == 416 || twiceCenter == 415 || twiceCenter == 417);
    }

    function litAt(battery as Number?) as Number {
        return frameWithBattery(battery).batteryLit.size();
    }

    function litColorAt(battery as Number) as Number {
        return frameWithBattery(battery).batteryLit[0].color;
    }

    function frameWithSteps(steps as Number?, goal as Number?) as Frame {
        var snapshot = new Snapshot(8, 42);
        snapshot.steps = steps;
        snapshot.stepGoal = goal;
        return FaceModel.compute(snapshot, Themes.mint());
    }

    function bezelSweepAt(steps as Number?, goal as Number?) as Number {
        return frameWithSteps(steps, goal).bezelProgress.sweep;
    }

    // The head dot, asserted to be there.
    function headAt(steps as Number, goal as Number) as Circle {
        var dot = frameWithSteps(steps, goal).bezelHead;
        Test.assert(dot != null);
        return dot as Circle;
    }

    function frameWithBodyBattery(bodyBattery as Number?) as Frame {
        var snapshot = new Snapshot(8, 42);
        snapshot.bodyBattery = bodyBattery;
        return FaceModel.compute(snapshot, Themes.mint());
    }

    function centerAt(bodyBattery as Number?) as FieldFrame {
        return frameWithBodyBattery(bodyBattery).centerField;
    }

    function frameWithStress(stress as Number?) as Frame {
        var snapshot = new Snapshot(8, 42);
        snapshot.stress = stress;
        return FaceModel.compute(snapshot, Themes.mint());
    }

    function leftAt(stress as Number?) as FieldFrame {
        return frameWithStress(stress).leftField;
    }

    function bottomAt(steps as Number?, goal as Number?) as BottomFieldFrame {
        return frameWithSteps(steps, goal).bottomField;
    }

    // The wearer's HR_ZONE_SPORT_GENERIC zones as the FR265 returned them
    // (ticket 02): indices 0-4 are the lower bounds of zones 1-5, 5 is max.
    function zones() as Array<Number> {
        return [96, 115, 134, 154, 173, 192] as Array<Number>;
    }

    function frameWithHeartRate(heartRate as Number?, heartRateZones as Array<Number>?) as Frame {
        var snapshot = new Snapshot(8, 42);
        snapshot.heartRate = heartRate;
        snapshot.heartRateZones = heartRateZones;
        return FaceModel.compute(snapshot, Themes.mint());
    }

    function rightAt(heartRate as Number?) as FieldFrame {
        return frameWithHeartRate(heartRate, zones()).rightField;
    }

    function litZonesAt(heartRate as Number?) as Number {
        return rightAt(heartRate).arcs.size();
    }

    // The static layer's well centered on (x, y), asserted to be there.
    function wellAt(x as Number, y as Number) as Circle {
        var wells = mintLayer().fieldWells;
        for (var i = 0; i < wells.size(); i++) {
            if (wells[i].x == x && wells[i].y == y) {
                return wells[i];
            }
        }
        Test.assertMessage(false, "no well at " + x + ", " + y);
        return wells[0];
    }

    // The static layer's track arcs centered on (x, y), in order.
    function tracksAt(x as Number, y as Number) as Array<Arc> {
        var tracks = mintLayer().fieldTracks;
        var found = [] as Array<Arc>;
        for (var i = 0; i < tracks.size(); i++) {
            if (tracks[i].x == x && tracks[i].y == y) {
                found.add(tracks[i]);
            }
        }
        return found;
    }

    // The single track arc centered on (x, y), asserted to be there.
    function trackAt(x as Number, y as Number) as Arc {
        var found = tracksAt(x, y);
        Test.assertEqual(1, found.size());
        return found[0];
    }

    // The gauge arc of a field, asserted to be there.
    function gaugeOf(field as FieldFrame) as Arc {
        Test.assertEqual(1, field.arcs.size());
        return field.arcs[0];
    }

    function assertLine(line as Line, x1 as Number, y1 as Number, x2 as Number,
            y2 as Number) as Void {
        Test.assertEqual(x1, line.x1);
        Test.assertEqual(y1, line.y1);
        Test.assertEqual(x2, line.x2);
        Test.assertEqual(y2, line.y2);
    }

    function aodAt(hour as Number, minute as Number) as AodFrame {
        return FaceModel.computeAod(new Snapshot(hour, minute), Themes.mint());
    }

    function aodOnDate(weekdayName as String?, weekdayNumber as Number, day as Number)
            as AodFrame {
        return FaceModel.computeAod(snapshotOnDate(weekdayName, weekdayNumber, day),
            Themes.mint());
    }

    // The AOD burn-in offset [x, y] for each minute of the hour, 0-59.
    function aodOffsets() as Array<Array<Number> > {
        var offsets = new Array<Array<Number> >[60];
        for (var m = 0; m < 60; m++) {
            var aod = aodAt(10, m);
            offsets[m] = [aod.offsetX, aod.offsetY] as Array<Number>;
        }
        return offsets;
    }

    function absOf(value as Number) as Number {
        return value < 0 ? -value : value;
    }

    // Consecutive offsets move by at least 3 px in x and in y.
    function assertMovesAtLeast3PxOnBothAxes(a as Array<Number>, b as Array<Number>) as Void {
        Test.assert(absOf(a[0] - b[0]) >= 3);
        Test.assert(absOf(a[1] - b[1]) >= 3);
    }

    (:test)
    function timeJustAfterMidnightHasLeadingZeros(logger as Test.Logger) as Boolean {
        Test.assertEqual("00:05", frameAt(0, 5).time);
        return true;
    }

    (:test)
    function singleDigitHourGetsLeadingZero(logger as Test.Logger) as Boolean {
        Test.assertEqual("09:00", frameAt(9, 0).time);
        return true;
    }

    (:test)
    function lastMinuteOfDayStaysTwentyFourHour(logger as Test.Logger) as Boolean {
        Test.assertEqual("23:59", frameAt(23, 59).time);
        return true;
    }

    (:test)
    function timeWidthIsTheSameWhateverTheDigits(logger as Test.Logger) as Boolean {
        var width = frameAt(0, 0).timeWidth;
        Test.assert(width > 0);
        Test.assertEqual(width, frameAt(11, 11).timeWidth);
        Test.assertEqual(width, frameAt(8, 42).timeWidth);
        return true;
    }

    (:test)
    function timeIsCenteredOnX208(logger as Test.Logger) as Boolean {
        var frame = frameAt(8, 42);
        var centerTwice = 2 * frame.timeX + frame.timeWidth;
        Test.assert(centerTwice >= 415 && centerTwice <= 417);
        return true;
    }

    (:test)
    function timeBaselineIsAtY135(logger as Test.Logger) as Boolean {
        // The renderer draws from the line top, which sits `base` above the baseline.
        Test.assertEqual(135, frameAt(8, 42).timeY + GlyphWidths.TIME_BASE);
        return true;
    }

    (:test)
    function mintTimeBandIsAccentWithBlackDigits(logger as Test.Logger) as Boolean {
        var frame = frameAt(8, 42);
        Test.assertEqual(0x8EE3B8, mintLayer().timeBandColor);
        Test.assertEqual(0x000000, frame.timeColor);
        return true;
    }

    (:test)
    function mintBackgroundDiscIsDarkGreyInBlackWells(logger as Test.Logger) as Boolean {
        var layer = mintLayer();
        Test.assertEqual(0x1A1D1B, layer.backgroundColor);
        Test.assertEqual(0x000000, layer.wellColor);
        return true;
    }

    // Battery segment i spans design -34 + 7i to -29 + 7i (arc contract):
    // ciq = 90 - design, drawn clockwise from start to end.
    (:test)
    function unlitBatterySegmentsSitAtTheConvertedDesignAngles(logger as Test.Logger) as Boolean {
        var segments = mintLayer().batteryTrack;
        Test.assertEqual(10, segments.size());
        Test.assertEqual(124, segments[0].start);
        Test.assertEqual(119, segments[0].end);
        Test.assertEqual(61, segments[9].start);
        Test.assertEqual(56, segments[9].end);
        return true;
    }

    (:test)
    function batteryLightsOneSegmentPerTenPercentRoundedUp(logger as Test.Logger) as Boolean {
        Test.assertEqual(0, litAt(0));
        Test.assertEqual(1, litAt(1));
        Test.assertEqual(1, litAt(10));
        Test.assertEqual(2, litAt(11));
        Test.assertEqual(2, litAt(20));
        Test.assertEqual(3, litAt(21));
        Test.assertEqual(8, litAt(78));
        Test.assertEqual(10, litAt(100));
        return true;
    }

    (:test)
    function missingBatteryLightsNoSegment(logger as Test.Logger) as Boolean {
        Test.assertEqual(0, litAt(null));
        return true;
    }

    (:test)
    function batteryAbove20IsAccent(logger as Test.Logger) as Boolean {
        Test.assertEqual(0x8EE3B8, litColorAt(21));
        Test.assertEqual(0x8EE3B8, litColorAt(78));
        Test.assertEqual(0x8EE3B8, litColorAt(100));
        return true;
    }

    (:test)
    function battery11To20IsOrange(logger as Test.Logger) as Boolean {
        Test.assertEqual(0xFF8A3D, litColorAt(20));
        Test.assertEqual(0xFF8A3D, litColorAt(11));
        return true;
    }

    (:test)
    function battery10OrLessIsRed(logger as Test.Logger) as Boolean {
        Test.assertEqual(0xFF4D4D, litColorAt(10));
        Test.assertEqual(0xFF4D4D, litColorAt(1));
        return true;
    }

    (:test)
    function litSegmentsLieOnTheUnlitOnes(logger as Test.Logger) as Boolean {
        var lit = frameWithBattery(100).batteryLit;
        Test.assertEqual(124, lit[0].start);
        Test.assertEqual(119, lit[0].end);
        Test.assertEqual(61, lit[9].start);
        Test.assertEqual(56, lit[9].end);
        return true;
    }

    (:test)
    function mintUnlitBatterySegmentsAreGaugeTrack(logger as Test.Logger) as Boolean {
        var segments = mintLayer().batteryTrack;
        Test.assertEqual(0x2E3330, segments[0].color);
        Test.assertEqual(180, segments[0].radius);
        Test.assertEqual(4, segments[0].pen);
        return true;
    }

    // Design -36 to +36 deg, r 180, pen 12: ciq 126 clockwise to 54.
    (:test)
    function batteryWellSpansDesignMinus36ToPlus36(logger as Test.Logger) as Boolean {
        var well = mintLayer().batteryWell;
        Test.assertEqual(126, well.start);
        Test.assertEqual(54, well.end);
        Test.assertEqual(72, well.sweep);
        Test.assertEqual(180, well.radius);
        Test.assertEqual(12, well.pen);
        Test.assertEqual(0x000000, well.color);
        return true;
    }

    // At design +-36 deg, r 180: x = 208 +- 105.8, y = 208 - 145.6.
    (:test)
    function batteryWellHasRoundCapsAtBothEnds(logger as Test.Logger) as Boolean {
        var caps = mintLayer().batteryCaps;
        Test.assertEqual(2, caps.size());
        Test.assertEqual(102, caps[0].x);
        Test.assertEqual(62, caps[0].y);
        Test.assertEqual(314, caps[1].x);
        Test.assertEqual(62, caps[1].y);
        Test.assertEqual(6, caps[0].radius);
        Test.assertEqual(0x000000, caps[1].color);
        return true;
    }

    (:test)
    function bezelTrackIsAFullCircle(logger as Test.Logger) as Boolean {
        var track = mintLayer().bezelTrack;
        Test.assertEqual(360, track.sweep);
        Test.assertEqual(track.start, track.end);
        Test.assertEqual(204, track.radius);
        Test.assertEqual(8, track.pen);
        Test.assertEqual(0x1E1E1E, track.color);
        return true;
    }

    (:test)
    function englishWeekdayIsUpperCasedBeforeTheDay(logger as Test.Logger) as Boolean {
        Test.assertEqual("THU 12", dateOf("Thu", 5, 12));
        return true;
    }

    // The FR265's real Vietnamese Thursday (ticket 02): "Th", U+1EE9, " 5".
    (:test)
    function vietnamesePrecomposedWeekdayFoldsToBaseLetters(logger as Test.Logger) as Boolean {
        Test.assertEqual("T5 12", dateOf(fromCodePoints([0x54, 0x68, 0x1EE9, 0x20, 0x35]), 5, 12));
        return true;
    }

    (:test)
    function missingWeekdayNameFallsBackToEnglish(logger as Test.Logger) as Boolean {
        Test.assertEqual("THU 12", dateOf(null, 5, 12));
        Test.assertEqual("SUN 1", dateOf(null, 1, 1));
        Test.assertEqual("SAT 31", dateOf(null, 7, 31));
        return true;
    }

    (:test)
    function emptyWeekdayNameFallsBackToEnglish(logger as Test.Logger) as Boolean {
        Test.assertEqual("MON 3", dateOf("", 2, 3));
        return true;
    }

    // Russian Thursday "Чт": the date font has no Cyrillic glyphs.
    (:test)
    function cyrillicWeekdayFallsBackToEnglish(logger as Test.Logger) as Boolean {
        Test.assertEqual("THU 12", dateOf(fromCodePoints([0x0427, 0x0442]), 5, 12));
        return true;
    }

    // Latin letters next to a character the font lacks still fall back.
    (:test)
    function weekdayWithAnUnknownCharacterFallsBackToEnglish(logger as Test.Logger) as Boolean {
        Test.assertEqual("WED 4", dateOf("Mer.", 4, 4));
        return true;
    }

    // "Thứ 5" decomposed: "Thu", combining horn U+031B, combining acute U+0301.
    (:test)
    function vietnameseCombiningMarksAreDropped(logger as Test.Logger) as Boolean {
        var name = fromCodePoints([0x54, 0x68, 0x75, 0x031B, 0x0301, 0x20, 0x35]);
        Test.assertEqual("T5 12", dateOf(name, 5, 12));
        // A mark from the supplement block (U+1DC4, macron-acute) on "a".
        Test.assertEqual("SA 1", dateOf(fromCodePoints([0x53, 0x61, 0x1DC4]), 7, 1));
        return true;
    }

    // Spanish "mié" (U+00E9), Czech "Čt" (U+010C), Romanian "Sâm" (U+00E2)
    // and a plain horned "ư" (U+01B0).
    (:test)
    function accentedLatinFoldsToBaseLetters(logger as Test.Logger) as Boolean {
        Test.assertEqual("MIE 4", dateOf(fromCodePoints([0x6D, 0x69, 0x00E9]), 4, 4));
        Test.assertEqual("CT 12", dateOf(fromCodePoints([0x010C, 0x74]), 5, 12));
        Test.assertEqual("SAM 14", dateOf(fromCodePoints([0x53, 0x00E2, 0x6D]), 7, 14));
        Test.assertEqual("TU 1", dateOf(fromCodePoints([0x54, 0x01B0]), 4, 1));
        return true;
    }

    (:test)
    function dayOfMonthHasNoLeadingZero(logger as Test.Logger) as Boolean {
        Test.assertEqual("FRI 5", dateOf("Fri", 6, 5));
        return true;
    }

    // The design's pill: (160, 140, 96, 28), radius 14, ink fill.
    (:test)
    function thu12FillsTheDesignedPill(logger as Test.Logger) as Boolean {
        var pill = frameOnDate("Thu", 5, 12).datePill;
        Test.assertEqual(160, pill.x);
        Test.assertEqual(140, pill.y);
        Test.assertEqual(96, pill.width);
        Test.assertEqual(28, pill.height);
        Test.assertEqual(14, pill.radius);
        Test.assertEqual(0x000000, pill.color);
        return true;
    }

    (:test)
    function mintDateTextIsWhite(logger as Test.Logger) as Boolean {
        Test.assertEqual(0xFFFFFF, frameOnDate("Thu", 5, 12).dateColor);
        return true;
    }

    // Design frame 1: the date's capitals span y 148-160 (centered on 154).
    (:test)
    function dateBaselineSitsOnY160(logger as Test.Logger) as Boolean {
        Test.assertEqual(160, frameOnDate("Thu", 5, 12).dateY + GlyphWidths.DATE_BASE);
        return true;
    }

    (:test)
    function shortDateKeepsTheMinimumPillWidth(logger as Test.Logger) as Boolean {
        Test.assertEqual(96, frameOnDate("Fri", 6, 5).datePill.width);
        return true;
    }

    (:test)
    function longerNameGrowsThePillCenteredOnX208(logger as Test.Logger) as Boolean {
        var frame = frameOnDate("Wednesday", 4, 28);
        var pill = frame.datePill;
        Test.assertEqual("WEDNESDAY 28", frame.date);
        Test.assert(pill.width > 96);
        Test.assert(pill.width <= 272);
        assertCenteredOn208(pill.x, pill.width);
        assertCenteredOn208(frame.dateX, frame.dateWidth);
        return true;
    }

    // Q33: a pill wider than the time band (272 px) falls back to English.
    (:test)
    function nameTooWideForTheTimeBandFallsBackToEnglish(logger as Test.Logger) as Boolean {
        var frame = frameOnDate("Wednesday Wednesday", 4, 28);
        Test.assertEqual("WED 28", frame.date);
        Test.assertEqual(frameOnDate("Wed", 4, 28).datePill.width, frame.datePill.width);
        return true;
    }

    // Q33 at its edge, with widths from the date font: 12 x M (17) + N (14)
    // + " 12" (27) = 245 px needs a 273 px pill and falls back; with B (13)
    // instead of N it is 244 px, a pill of exactly 272, and is kept.
    (:test)
    function pillOfExactlyTheBandWidthIsKept(logger as Test.Logger) as Boolean {
        var frame = frameOnDate("MMMMMMMMMMMMB", 5, 12);
        Test.assertEqual("MMMMMMMMMMMMB 12", frame.date);
        Test.assertEqual(272, frame.datePill.width);
        return true;
    }

    (:test)
    function pillOnePixelWiderThanTheBandFallsBack(logger as Test.Logger) as Boolean {
        Test.assertEqual("THU 12", dateOf("MMMMMMMMMMMMN", 5, 12));
        return true;
    }

    // Q21: "Thứ 2" ... "Thứ 7" are shown as T2 ... T7.
    (:test)
    function vietnameseWeekdaysUseTheShortForm(logger as Test.Logger) as Boolean {
        Test.assertEqual("T2 9", dateOf(fromCodePoints([0x54, 0x68, 0x1EE9, 0x20, 0x32]), 2, 9));
        Test.assertEqual("T7 14", dateOf(fromCodePoints([0x54, 0x68, 0x1EE9, 0x20, 0x37]), 7, 14));
        return true;
    }

    // Q21: Sunday "Chủ nhật" (U+1EE7, U+1EAD) is shown as CN.
    (:test)
    function vietnameseSundayIsCN(logger as Test.Logger) as Boolean {
        var name = fromCodePoints([0x43, 0x68, 0x1EE7, 0x20, 0x6E, 0x68, 0x1EAD, 0x74]);
        Test.assertEqual("CN 15", dateOf(name, 1, 15));
        Test.assertEqual("CN 15", dateOf("CN", 1, 15));
        return true;
    }

    // Only "THU" + one digit 2-7 is shortened.
    (:test)
    function otherNamesAreNotShortened(logger as Test.Logger) as Boolean {
        Test.assertEqual("THU 8 3", dateOf("Thu 8", 5, 3));
        Test.assertEqual("THU 12", dateOf("Thu", 5, 12));
        return true;
    }

    // Bezel progress (arc contract): from design 0 deg (ciq 90) clockwise,
    // sweep = min(steps, goal) x 360 / goal, rounded down.
    (:test)
    function halfTheGoalFillsHalfTheBezelFrom12OClock(logger as Test.Logger) as Boolean {
        var progress = frameWithSteps(1555, 3110).bezelProgress;
        Test.assertEqual(180, progress.sweep);
        Test.assertEqual(90, progress.start);
        Test.assertEqual(270, progress.end);
        Test.assertEqual(204, progress.radius);
        Test.assertEqual(8, progress.pen);
        Test.assertEqual(0x8EE3B8, progress.color);
        return true;
    }

    (:test)
    function overTheGoalTheBezelIsAFullCircle(logger as Test.Logger) as Boolean {
        var progress = frameWithSteps(3512, 3110).bezelProgress;
        Test.assertEqual(360, progress.sweep);
        // A full circle in the arc contract: start == end.
        Test.assertEqual(90, progress.start);
        Test.assertEqual(90, progress.end);
        return true;
    }

    // Story 29, Q26: no goal, no progress, and no division by zero.
    (:test)
    function goalZeroLeavesTheBezelEmpty(logger as Test.Logger) as Boolean {
        Test.assertEqual(0, bezelSweepAt(1147, 0));
        return true;
    }

    (:test)
    function zeroStepsDrawNoBezelArc(logger as Test.Logger) as Boolean {
        Test.assertEqual(0, bezelSweepAt(0, 3110));
        return true;
    }

    // 360 / 3110 rounds down to 0 degrees.
    (:test)
    function oneStepOf3110DrawsNoBezelArc(logger as Test.Logger) as Boolean {
        Test.assertEqual(0, bezelSweepAt(1, 3110));
        return true;
    }

    // Story 24: 3109 x 360 / 3110 = 359.88, rounded down, so never closed early.
    (:test)
    function oneStepShortOfTheGoalIsNotAFullRing(logger as Test.Logger) as Boolean {
        Test.assertEqual(359, bezelSweepAt(3109, 3110));
        return true;
    }

    (:test)
    function exactlyTheGoalClosesTheRing(logger as Test.Logger) as Boolean {
        Test.assertEqual(360, bezelSweepAt(3110, 3110));
        return true;
    }

    (:test)
    function missingGoalLeavesTheBezelEmpty(logger as Test.Logger) as Boolean {
        Test.assertEqual(0, bezelSweepAt(1147, null)); // Q26
        return true;
    }

    // Story 30, Q26.
    (:test)
    function missingStepsLeaveTheBezelEmpty(logger as Test.Logger) as Boolean {
        Test.assertEqual(0, bezelSweepAt(null, 3110));
        return true;
    }

    // The head dot sits on the bezel centerline (r 204) at the progress
    // head: design angle a gives (208 + 204 sin a, 208 - 204 cos a).
    (:test)
    function headDotAtHalfTheGoalSitsAt6OClock(logger as Test.Logger) as Boolean {
        var dot = headAt(1555, 3110);
        Test.assertEqual(208, dot.x);
        Test.assertEqual(412, dot.y);
        Test.assertEqual(4, dot.radius);
        Test.assertEqual(0xFFFFFF, dot.color);
        return true;
    }

    // Story 25: with 0 steps there is no arc, but the dot shows at 12 o'clock.
    (:test)
    function headDotAtZeroStepsSitsAt12OClock(logger as Test.Logger) as Boolean {
        var dot = headAt(0, 3110);
        Test.assertEqual(208, dot.x);
        Test.assertEqual(4, dot.y);
        return true;
    }

    // 90 deg is 3 o'clock: (208 + 204, 208).
    (:test)
    function headDotAtAQuarterSitsAt3OClock(logger as Test.Logger) as Boolean {
        var dot = headAt(1000, 4000);
        Test.assertEqual(412, dot.x);
        Test.assertEqual(208, dot.y);
        return true;
    }

    (:test)
    function headDotIsHiddenWithoutAGoalOrSteps(logger as Test.Logger) as Boolean {
        Test.assert(frameWithSteps(1147, 0).bezelHead == null);
        Test.assert(frameWithSteps(1147, null).bezelHead == null);
        Test.assert(frameWithSteps(null, 3110).bezelHead == null);
        return true;
    }

    (:test)
    function goalIsReachedAtExactlyTheGoal(logger as Test.Logger) as Boolean {
        Test.assert(!frameWithSteps(3109, 3110).stepGoalReached);
        Test.assert(frameWithSteps(3110, 3110).stepGoalReached);
        Test.assert(frameWithSteps(3512, 3110).stepGoalReached);
        return true;
    }

    // Story 29, Q26: steps >= 0 holds for goal 0, but there is no goal to reach.
    (:test)
    function goalZeroIsNeverReached(logger as Test.Logger) as Boolean {
        Test.assert(!frameWithSteps(1147, 0).stepGoalReached);
        return true;
    }

    (:test)
    function missingStepsNeverReachTheGoal(logger as Test.Logger) as Boolean {
        Test.assert(!frameWithSteps(null, 3110).stepGoalReached);
        Test.assert(!frameWithSteps(1147, null).stepGoalReached);
        return true;
    }

    // Story 25: black lines across the ring at 3, 6 and 9 o'clock (design
    // 90, 180 and 270 deg), from r 198 to r 210, pen 3, whatever the steps.
    (:test)
    function bezelNotchesCrossTheRingAt3And6And9OClock(logger as Test.Logger) as Boolean {
        var notches = FaceModel.bezelNotches(Themes.mint());
        Test.assertEqual(3, notches.size());
        assertLine(notches[0], 406, 208, 418, 208);
        assertLine(notches[1], 208, 406, 208, 418);
        assertLine(notches[2], 10, 208, -2, 208);
        for (var i = 0; i < notches.size(); i++) {
            Test.assertEqual(3, notches[i].pen);
            Test.assertEqual(0x000000, notches[i].color);
        }
        return true;
    }


    // A negative count is not a real reading, so it counts as missing.
    (:test)
    function negativeStepsCountAsMissing(logger as Test.Logger) as Boolean {
        var frame = frameWithSteps(-1, 3110);
        Test.assertEqual(0, frame.bezelProgress.sweep);
        Test.assert(frame.bezelHead == null);
        Test.assert(!frame.stepGoalReached);
        return true;
    }

    // Story 10: the center gauge fills clockwise from 12 o'clock; 100 is a
    // full circle (start == end) around the center field (208, 246), pen 9.
    (:test)
    function bodyBattery100IsAFullCircle(logger as Test.Logger) as Boolean {
        var gauge = gaugeOf(centerAt(100));
        Test.assertEqual(360, gauge.sweep);
        Test.assertEqual(90, gauge.start);
        Test.assertEqual(90, gauge.end);
        Test.assertEqual(208, gauge.x);
        Test.assertEqual(246, gauge.y);
        Test.assert(gauge.radius == 55 || gauge.radius == 56);
        Test.assertEqual(9, gauge.pen);
        return true;
    }

    // Design frame 1: 56 sweeps 201 deg (56 x 360 / 100, rounded down), so
    // from ciq 90 clockwise to ciq 249, in the accent.
    (:test)
    function bodyBattery56SweepsFrom12OClock(logger as Test.Logger) as Boolean {
        var gauge = gaugeOf(centerAt(56));
        Test.assertEqual(201, gauge.sweep);
        Test.assertEqual(90, gauge.start);
        Test.assertEqual(249, gauge.end);
        Test.assertEqual(0x8EE3B8, gauge.color);
        return true;
    }

    (:test)
    function bodyBattery0DrawsNoArc(logger as Test.Logger) as Boolean {
        Test.assertEqual(0, centerAt(0).arcs.size());
        return true;
    }

    // Story 9: the value as a large white number.
    (:test)
    function bodyBatteryIsAWhiteNumber(logger as Test.Logger) as Boolean {
        var field = centerAt(56);
        Test.assertEqual("56", field.number);
        Test.assertEqual(0xFFFFFF, field.numberColor);
        return true;
    }

    // Story 13, Q26: missing Body Battery is "--" in gray, track only.
    (:test)
    function missingBodyBatteryIsGrayDashesWithNoArc(logger as Test.Logger) as Boolean {
        var field = centerAt(null);
        Test.assertEqual("--", field.number);
        Test.assertEqual(0x8C8C8C, field.numberColor);
        Test.assertEqual(0, field.arcs.size());
        return true;
    }

    // Story 11: 25 and up is no warning: accent gauge, white number.
    (:test)
    function bodyBattery25IsNoWarning(logger as Test.Logger) as Boolean {
        var field = centerAt(25);
        Test.assertEqual(0x8EE3B8, gaugeOf(field).color);
        Test.assertEqual(0xFFFFFF, field.numberColor);
        return true;
    }

    // Story 11: 15-24 turns the gauge and number orange.
    (:test)
    function bodyBattery15To24IsOrange(logger as Test.Logger) as Boolean {
        var values = [15, 24] as Array<Number>;
        for (var i = 0; i < values.size(); i++) {
            var field = centerAt(values[i]);
            Test.assertEqual(0xFF8A3D, gaugeOf(field).color);
            Test.assertEqual(0xFF8A3D, field.numberColor);
        }
        return true;
    }

    // Story 11: below 15 turns the gauge and number red.
    (:test)
    function bodyBatteryBelow15IsRed(logger as Test.Logger) as Boolean {
        var field = centerAt(14);
        Test.assertEqual(0xFF4D4D, gaugeOf(field).color);
        Test.assertEqual(0xFF4D4D, field.numberColor);
        Test.assertEqual(0xFF4D4D, centerAt(0).numberColor);
        return true;
    }

    // Story 12: the bolt (U+E000 in the icon font) at (196, 203), gray
    // without a warning, including when the value is missing.
    (:test)
    function bodyBatteryIconIsAGrayBoltWithoutWarning(logger as Test.Logger) as Boolean {
        var values = [56, 25, null] as Array<Number?>;
        for (var i = 0; i < values.size(); i++) {
            var field = centerAt(values[i]);
            Test.assertEqual((0xE000).toChar().toString(), field.icon);
            Test.assertEqual(196, field.iconX);
            Test.assertEqual(203, field.iconY);
            Test.assertEqual(0x8C8C8C, field.iconColor);
        }
        return true;
    }

    // Story 11: in warning the icon takes the warning color too.
    (:test)
    function bodyBatteryIconTakesTheWarningColor(logger as Test.Logger) as Boolean {
        Test.assertEqual(0xFF8A3D, centerAt(24).iconColor);
        Test.assertEqual(0xFF8A3D, centerAt(15).iconColor);
        Test.assertEqual(0xFF4D4D, centerAt(14).iconColor);
        return true;
    }

    // Story 9: Manrope ExtraBold 48, centered on x 208 by its measured width
    // ("5" 28 + "6" 30 px in the generated font).
    (:test)
    function bodyBatteryNumberIsCenteredOnX208(logger as Test.Logger) as Boolean {
        var field = centerAt(56);
        Test.assertEqual(NUMBER_FONT_48, field.numberFont);
        Test.assertEqual(58, field.numberWidth);
        assertCenteredOn208(field.numberX, field.numberWidth);
        var dashes = centerAt(null);
        assertCenteredOn208(dashes.numberX, dashes.numberWidth);
        return true;
    }

    // The digits are vertically centered on y 258: with a 35 px cap height
    // the baseline sits on 258 + 17 = 275. The renderer draws from the line
    // top, `base` above the baseline.
    (:test)
    function bodyBatteryBaselineSitsOnY275(logger as Test.Logger) as Boolean {
        Test.assertEqual(275, centerAt(56).numberY + GlyphWidths.NUMBER_48_BASE);
        Test.assertEqual(275, centerAt(null).numberY + GlyphWidths.NUMBER_48_BASE);
        return true;
    }

    // The center field sits in a black well of r 60 + 6 around (208, 246).
    (:test)
    function centerFieldHasABlackWell(logger as Test.Logger) as Boolean {
        var well = wellAt(208, 246);
        Test.assertEqual(66, well.radius);
        Test.assertEqual(0x000000, well.color);
        return true;
    }

    // The gauge track is a full circle in the gauge-track color, exactly
    // under the gauge (same center, radius and pen).
    (:test)
    function centerGaugeTrackIsAFullCircleUnderTheGauge(logger as Test.Logger) as Boolean {
        var track = trackAt(208, 246);
        var gauge = gaugeOf(centerAt(100));
        Test.assertEqual(360, track.sweep);
        Test.assertEqual(0x2E3330, track.color);
        Test.assertEqual(gauge.x, track.x);
        Test.assertEqual(gauge.y, track.y);
        Test.assertEqual(gauge.radius, track.radius);
        Test.assertEqual(gauge.pen, track.pen);
        return true;
    }

    // Story 14, design frame 1: stress 27 sweeps 97 deg (27 x 360 / 100,
    // rounded down) from 12 o'clock around the left field (88, 236), on the
    // design's ring centerline r 35 (38 - 6 / 2), pen 6, in the accent.
    (:test)
    function stress27SweepsFrom12OClockInTheLeftField(logger as Test.Logger) as Boolean {
        var gauge = gaugeOf(leftAt(27));
        Test.assertEqual(97, gauge.sweep);
        Test.assertEqual(90, gauge.start);
        Test.assertEqual(353, gauge.end);
        Test.assertEqual(88, gauge.x);
        Test.assertEqual(236, gauge.y);
        Test.assertEqual(35, gauge.radius);
        Test.assertEqual(6, gauge.pen);
        Test.assertEqual(0x8EE3B8, gauge.color);
        return true;
    }

    // Story 15: up to 50 is no warning: accent gauge, white number, gray icon.
    (:test)
    function stress50IsNoWarning(logger as Test.Logger) as Boolean {
        var field = leftAt(50);
        Test.assertEqual(0x8EE3B8, gaugeOf(field).color);
        Test.assertEqual(0xFFFFFF, field.numberColor);
        Test.assertEqual(0x8C8C8C, field.iconColor);
        return true;
    }

    // Story 15: 51-75 turns the gauge, icon and number orange.
    (:test)
    function stress51To75IsOrange(logger as Test.Logger) as Boolean {
        var values = [51, 75] as Array<Number>;
        for (var i = 0; i < values.size(); i++) {
            var field = leftAt(values[i]);
            Test.assertEqual(0xFF8A3D, gaugeOf(field).color);
            Test.assertEqual(0xFF8A3D, field.numberColor);
            Test.assertEqual(0xFF8A3D, field.iconColor);
        }
        return true;
    }

    // Story 15: above 75 turns the gauge, icon and number red.
    (:test)
    function stressAbove75IsRed(logger as Test.Logger) as Boolean {
        var field = leftAt(76);
        Test.assertEqual(0xFF4D4D, gaugeOf(field).color);
        Test.assertEqual(0xFF4D4D, field.numberColor);
        Test.assertEqual(0xFF4D4D, field.iconColor);
        return true;
    }

    // The stress wave (U+E001 in the icon font) with its top-left at
    // (88 - 12, 236 - 30).
    (:test)
    function stressIconIsTheWaveAboveTheNumber(logger as Test.Logger) as Boolean {
        var field = leftAt(27);
        Test.assertEqual((0xE001).toChar().toString(), field.icon);
        Test.assertEqual(76, field.iconX);
        Test.assertEqual(206, field.iconY);
        return true;
    }

    // Story 16, design frame 11: missing stress is "--" in gray with the
    // gauge off and a gray icon.
    (:test)
    function missingStressIsGrayDashesWithNoArc(logger as Test.Logger) as Boolean {
        var field = leftAt(null);
        Test.assertEqual("--", field.number);
        Test.assertEqual(0x8C8C8C, field.numberColor);
        Test.assertEqual(0x8C8C8C, field.iconColor);
        Test.assertEqual(0, field.arcs.size());
        return true;
    }

    // Story 17: up to 3 characters use 26 px ("--" included).
    (:test)
    function leftNumberUpTo3CharactersIs26(logger as Test.Logger) as Boolean {
        Test.assertEqual(NUMBER_FONT_26, leftAt(7).numberFont);
        Test.assertEqual(NUMBER_FONT_26, leftAt(100).numberFont);
        Test.assertEqual(NUMBER_FONT_26, leftAt(null).numberFont);
        return true;
    }

    // Story 17: 4 characters use 22 px. Stress stops at 100; the size rule
    // belongs to the field, for the metrics it may show later (Q15).
    (:test)
    function leftNumberOf4CharactersIs22(logger as Test.Logger) as Boolean {
        Test.assertEqual(NUMBER_FONT_22, leftAt(1000).numberFont);
        return true;
    }

    // Story 17: 5 characters or more use 18 px.
    (:test)
    function leftNumberOf5CharactersIs18(logger as Test.Logger) as Boolean {
        Test.assertEqual(NUMBER_FONT_18, leftAt(10000).numberFont);
        Test.assertEqual(NUMBER_FONT_18, leftAt(100000).numberFont);
        return true;
    }

    // Centered on the field's x 88 by the measured width in its font:
    // "27" is 16 + 14 px at 26 px.
    (:test)
    function leftNumberIsCenteredOnX88(logger as Test.Logger) as Boolean {
        var field = leftAt(27);
        Test.assertEqual(30, field.numberWidth);
        Test.assertEqual(73, field.numberX);
        return true;
    }

    // The digits are vertically centered on y 250: at 26 px (cap height 19)
    // the baseline sits on 250 + 9 = 259; at 22 px (cap 16) on 258.
    (:test)
    function leftNumberBaselineFollowsItsFont(logger as Test.Logger) as Boolean {
        Test.assertEqual(259, leftAt(27).numberY + GlyphWidths.NUMBER_26_BASE);
        Test.assertEqual(258, leftAt(1000).numberY + GlyphWidths.NUMBER_22_BASE);
        return true;
    }

    // The left field sits in a black well of r 38 + 6 around (88, 236).
    (:test)
    function leftFieldHasABlackWell(logger as Test.Logger) as Boolean {
        var well = wellAt(88, 236);
        Test.assertEqual(44, well.radius);
        Test.assertEqual(0x000000, well.color);
        return true;
    }

    // The left gauge track: a full circle in the gauge-track color, exactly
    // under the gauge.
    (:test)
    function leftGaugeTrackIsAFullCircleUnderTheGauge(logger as Test.Logger) as Boolean {
        var track = trackAt(88, 236);
        var gauge = gaugeOf(leftAt(100));
        Test.assertEqual(360, track.sweep);
        Test.assertEqual(0x2E3330, track.color);
        Test.assertEqual(gauge.radius, track.radius);
        Test.assertEqual(gauge.pen, track.pen);
        return true;
    }

    // Story 18: zone 1 lights segment 0, which spans design 4 to 68 deg
    // (ciq 86 clockwise to 22) around the right field (328, 236), r 35,
    // pen 6, in the accent.
    (:test)
    function zone1LightsSegment0FromDesign4To68(logger as Test.Logger) as Boolean {
        var field = rightAt(100);
        Test.assertEqual(1, field.arcs.size());
        var segment = field.arcs[0];
        Test.assertEqual(86, segment.start);
        Test.assertEqual(22, segment.end);
        Test.assertEqual(64, segment.sweep);
        Test.assertEqual(328, segment.x);
        Test.assertEqual(236, segment.y);
        Test.assertEqual(35, segment.radius);
        Test.assertEqual(6, segment.pen);
        return true;
    }

    // Story 18: below zone 1's lower bound (96) nothing is lit.
    (:test)
    function heartRateBelowZone1LightsNoSegment(logger as Test.Logger) as Boolean {
        Test.assertEqual(0, litZonesAt(95));
        return true;
    }

    // A heart rate exactly on a lower bound counts as that zone: 134 is
    // zone 3's lower bound, so three segments light.
    (:test)
    function heartRateOnALowerBoundCountsAsThatZone(logger as Test.Logger) as Boolean {
        Test.assertEqual(3, litZonesAt(134));
        Test.assertEqual(2, litZonesAt(133));
        return true;
    }

    // From zone 5's lower bound up (and above max HR) all five light.
    (:test)
    function heartRateAboveZone5LightsAllFiveSegments(logger as Test.Logger) as Boolean {
        Test.assertEqual(5, litZonesAt(173));
        Test.assertEqual(5, litZonesAt(200));
        return true;
    }

    // Segment 4 (zone 5) spans design 292 to 356 deg: ciq 158 clockwise to 94.
    (:test)
    function zone5SegmentSpansDesign292To356(logger as Test.Logger) as Boolean {
        var segment = rightAt(200).arcs[4];
        Test.assertEqual(158, segment.start);
        Test.assertEqual(94, segment.end);
        return true;
    }

    // Each lit segment takes its own zone's color, in Garmin's order (Q37):
    // zone 1 gray, 2 blue, 3 green, 4 orange, 5 red.
    (:test)
    function eachLitSegmentTakesItsZoneColor(logger as Test.Logger) as Boolean {
        var segments = rightAt(200).arcs;
        var expected = [0xB4B4B4, 0x4DA6FF, 0x4CD964, 0xFF8A3D, 0xFF4D4D] as Array<Number>;
        for (var i = 0; i < expected.size(); i++) {
            Test.assertEqual(expected[i], segments[i].color);
        }
        // Zone 3 lights zones 1-3 in their own colors, not the current zone's.
        Test.assertEqual(0xB4B4B4, rightAt(142).arcs[0].color);
        return true;
    }

    // Story 20: without zones nothing is lit, but the number still shows.
    (:test)
    function missingZonesLightNothingButShowTheNumber(logger as Test.Logger) as Boolean {
        var field = frameWithHeartRate(120, null).rightField;
        Test.assertEqual(0, field.arcs.size());
        Test.assertEqual("120", field.number);
        Test.assertEqual(0xFFFFFF, field.numberColor);
        Test.assertEqual(0, frameWithHeartRate(120, [96, 115] as Array<Number>)
            .rightField.arcs.size());
        return true;
    }

    // Story 19, design frame 11: missing heart rate is "--" in gray with
    // every segment off.
    (:test)
    function missingHeartRateIsGrayDashesWithNoSegment(logger as Test.Logger) as Boolean {
        var field = rightAt(null);
        Test.assertEqual("--", field.number);
        Test.assertEqual(0x8C8C8C, field.numberColor);
        Test.assertEqual(0, field.arcs.size());
        return true;
    }

    // The filled heart (U+E002 in the icon font) with its top-left at
    // (328 - 12, 236 - 30), always gray.
    (:test)
    function heartRateIconIsAGrayHeart(logger as Test.Logger) as Boolean {
        var values = [62, 200, null] as Array<Number?>;
        for (var i = 0; i < values.size(); i++) {
            var field = rightAt(values[i]);
            Test.assertEqual((0xE002).toChar().toString(), field.icon);
            Test.assertEqual(316, field.iconX);
            Test.assertEqual(206, field.iconY);
            Test.assertEqual(0x8C8C8C, field.iconColor);
        }
        return true;
    }

    // Story 21: heart rate has no warning color: the number stays white and
    // the icon gray whether low or high (zones 4 and 5 are zone colors).
    (:test)
    function heartRateHasNoWarningColor(logger as Test.Logger) as Boolean {
        var values = [30, 142, 200] as Array<Number>;
        for (var i = 0; i < values.size(); i++) {
            var field = rightAt(values[i]);
            Test.assertEqual(0xFFFFFF, field.numberColor);
            Test.assertEqual(0x8C8C8C, field.iconColor);
        }
        return true;
    }

    // Story 17 for the right field: 62 is 26 px, centered on x 328 ("6" 16 +
    // "2" 16 px). 4 characters would be 22 px (heart rate never reaches it).
    (:test)
    function rightNumberSizeFollowsItsLength(logger as Test.Logger) as Boolean {
        var field = rightAt(62);
        Test.assertEqual(NUMBER_FONT_26, field.numberFont);
        Test.assertEqual(32, field.numberWidth);
        Test.assertEqual(312, field.numberX);
        Test.assertEqual(259, field.numberY + GlyphWidths.NUMBER_26_BASE);
        Test.assertEqual(NUMBER_FONT_22, rightAt(1000).numberFont);
        return true;
    }

    // The right field sits in a black well of r 38 + 6 around (328, 236).
    (:test)
    function rightFieldHasABlackWell(logger as Test.Logger) as Boolean {
        var well = wellAt(328, 236);
        Test.assertEqual(44, well.radius);
        Test.assertEqual(0x000000, well.color);
        return true;
    }

    // Its track is the five unlit segments in the gauge-track color, not a
    // full circle: segment 0 spans ciq 86 to 22 like the lit one.
    (:test)
    function rightFieldTrackIsFiveUnlitSegments(logger as Test.Logger) as Boolean {
        var segments = tracksAt(328, 236);
        Test.assertEqual(5, segments.size());
        for (var i = 0; i < segments.size(); i++) {
            Test.assertEqual(64, segments[i].sweep);
            Test.assertEqual(35, segments[i].radius);
            Test.assertEqual(6, segments[i].pen);
            Test.assertEqual(0x2E3330, segments[i].color);
        }
        Test.assertEqual(86, segments[0].start);
        Test.assertEqual(22, segments[0].end);
        return true;
    }

    // Story 22, design frame 1: "1.147" (22 px, 53 wide) right-aligned at
    // x 228, "/ 3.110" (Bold 15, 47 wide) left-aligned at x 233, the foot
    // at (140, 328). It fits: 175 >= 164 and 280 <= 286.
    (:test)
    function stepsAndGoalSitAtTheirAnchors(logger as Test.Logger) as Boolean {
        var field = bottomAt(1147, 3110);
        Test.assertEqual("1.147", field.number);
        Test.assertEqual(NUMBER_FONT_22, field.numberFont);
        Test.assertEqual(175, field.numberX);
        Test.assertEqual("/ 3.110", field.goal);
        Test.assertEqual(233, field.goalX);
        Test.assertEqual((0xE003).toChar().toString(), field.icon);
        Test.assertEqual(140, field.iconX);
        Test.assertEqual(328, field.iconY);
        return true;
    }

    // Story 28: "10.000" is 77 px at 22 (would start at 151 < 164), so it
    // drops to 18 px (62 wide) at the same anchor: 228 - 62 = 166. The goal
    // "/ 11.111" (49) ends at 282 <= 286, so the foot and goal stay.
    (:test)
    function fiveDigitStepsShrinkTo18(logger as Test.Logger) as Boolean {
        var field = bottomAt(10000, 11111);
        Test.assertEqual(NUMBER_FONT_18, field.numberFont);
        Test.assertEqual(166, field.numberX);
        Test.assertEqual("/ 11.111", field.goal);
        Test.assertEqual(233, field.goalX);
        Test.assertEqual((0xE003).toChar().toString(), field.icon);
        return true;
    }

    // The number's left edge on the limit: "2.004" (64 px) starts at 164
    // and stays at 22 px; "2.000" (65 px) would start at 163, so it drops to
    // 18 px (53 wide): 228 - 53 = 175.
    (:test)
    function numberStartingAt164StaysAt22(logger as Test.Logger) as Boolean {
        var fits = bottomAt(2004, null);
        Test.assertEqual(NUMBER_FONT_22, fits.numberFont);
        Test.assertEqual(164, fits.numberX);
        var shrunk = bottomAt(2000, null);
        Test.assertEqual(NUMBER_FONT_18, shrunk.numberFont);
        Test.assertEqual(175, shrunk.numberX);
        return true;
    }

    // The goal's right edge on the limit: "/ 10.117" (53 px) ends at 286 and
    // stays beside the foot; "/ 10.112" (54 px) would end at 287, so the
    // foot hides and the text is centered.
    (:test)
    function goalEndingAt286KeepsTheFoot(logger as Test.Logger) as Boolean {
        var fits = bottomAt(1147, 10117);
        Test.assertEqual((0xE003).toChar().toString(), fits.icon);
        Test.assertEqual(233, fits.goalX);
        Test.assertEqual("", bottomAt(1147, 10112).icon);
        return true;
    }

    // The centered group on the limit: "100.000" (74 at 18) + 5 +
    // "/ 111.117" (57) = 136 keeps the goal, number at 208 - 68 = 140 and
    // goal at 140 + 74 + 5 = 219; "/ 111.112" (58) makes 137, so the goal
    // is dropped.
    (:test)
    function centeredGroupOf136KeepsTheGoal(logger as Test.Logger) as Boolean {
        var fits = bottomAt(100000, 111117);
        Test.assertEqual("/ 111.117", fits.goal);
        Test.assertEqual(140, fits.numberX);
        Test.assertEqual(219, fits.goalX);
        Test.assertEqual("", bottomAt(100000, 111112).goal);
        return true;
    }

    // Q24: "/ 10.000" (61 px) would end at 294 > 286 whatever the number's
    // size, so the foot hides and "1.147" (18 px, 43) + 5 + 61 = 109 px is
    // centered on 208: number at 208 - 54 = 154, goal at 154 + 43 + 5 = 202.
    (:test)
    function aFiveDigitGoalHidesTheFootAndCentersTheText(logger as Test.Logger) as Boolean {
        var field = bottomAt(1147, 10000);
        Test.assertEqual("", field.icon);
        Test.assertEqual(NUMBER_FONT_18, field.numberFont);
        Test.assertEqual("/ 10.000", field.goal);
        Test.assertEqual(154, field.numberX);
        Test.assertEqual(202, field.goalX);
        return true;
    }

    // "12.345" (58 at 18) + 5 + "/ 20.000" (63) = 126 px, centered:
    // number at 208 - 63 = 145, goal at 145 + 58 + 5 = 208.
    (:test)
    function fiveDigitStepsAndGoalCenterWithoutTheFoot(logger as Test.Logger) as Boolean {
        var field = bottomAt(12345, 20000);
        Test.assertEqual("", field.icon);
        Test.assertEqual(145, field.numberX);
        Test.assertEqual(208, field.goalX);
        return true;
    }

    // Q34: "100.000" (74 at 18) + 5 + "/ 200.000" (73) = 152 > 136, so
    // "/ goal" is dropped and the number alone is centered: 208 - 37 = 171.
    (:test)
    function sixDigitStepsDropTheGoal(logger as Test.Logger) as Boolean {
        var field = bottomAt(100000, 200000);
        Test.assertEqual("100.000", field.number);
        Test.assertEqual("", field.goal);
        Test.assertEqual("", field.icon);
        Test.assertEqual(NUMBER_FONT_18, field.numberFont);
        Test.assertEqual(171, field.numberX);
        return true;
    }

    // Q25, design frame 7 changed: goal reached shows the foot and "3.512"
    // (22 px, 56 wide) centered as a group of 24 + 4 + 56 = 84 px: foot at
    // 208 - 42 = 166, number at 166 + 28 = 194; no "/ goal".
    (:test)
    function goalReachedCentersFootAndNumber(logger as Test.Logger) as Boolean {
        var field = bottomAt(3512, 3110);
        Test.assertEqual(166, field.iconX);
        Test.assertEqual(328, field.iconY);
        Test.assertEqual(NUMBER_FONT_22, field.numberFont);
        Test.assertEqual(194, field.numberX);
        Test.assertEqual("", field.goal);
        return true;
    }

    // Five digits reached: 24 + 4 + 70 = 98 px fits within 136 at 22 px:
    // foot at 208 - 49 = 159, number at 187.
    (:test)
    function goalReachedWithFiveDigitsStaysAt22(logger as Test.Logger) as Boolean {
        var field = bottomAt(12345, 10000);
        Test.assertEqual(NUMBER_FONT_22, field.numberFont);
        Test.assertEqual(159, field.iconX);
        Test.assertEqual(187, field.numberX);
        Test.assertEqual("", field.goal);
        return true;
    }

    // Reached, on the limit: "1.000.014" (108 px) makes a 24 + 4 + 108 = 136
    // group and stays at 22 px (foot at 140, number at 168); "1.000.001"
    // (109) would make 137, so it drops to 18 px (88 wide): a 116 px group,
    // foot at 208 - 58 = 150, number at 178.
    (:test)
    function reachedGroupOf136StaysAt22(logger as Test.Logger) as Boolean {
        var fits = bottomAt(1000014, 3110);
        Test.assertEqual(NUMBER_FONT_22, fits.numberFont);
        Test.assertEqual(140, fits.iconX);
        Test.assertEqual(168, fits.numberX);
        var shrunk = bottomAt(1000001, 3110);
        Test.assertEqual(NUMBER_FONT_18, shrunk.numberFont);
        Test.assertEqual(150, shrunk.iconX);
        Test.assertEqual(178, shrunk.numberX);
        return true;
    }

    // Story 26: reached is the accent pill with a black foot and number.
    (:test)
    function goalReachedIsAnAccentPillWithBlackText(logger as Test.Logger) as Boolean {
        var field = bottomAt(3512, 3110);
        Test.assertEqual(0x8EE3B8, field.pill.color);
        Test.assertEqual(0x000000, field.iconColor);
        Test.assertEqual(0x000000, field.numberColor);
        return true;
    }

    // The pill is (126, 320, 164, 40) with radius 20, reached or not.
    (:test)
    function bottomFieldPillIsTheDesignedRoundedRect(logger as Test.Logger) as Boolean {
        var values = [1147, 3512] as Array<Number>;
        for (var i = 0; i < values.size(); i++) {
            var pill = bottomAt(values[i], 3110).pill;
            Test.assertEqual(126, pill.x);
            Test.assertEqual(320, pill.y);
            Test.assertEqual(164, pill.width);
            Test.assertEqual(40, pill.height);
            Test.assertEqual(20, pill.radius);
        }
        return true;
    }

    // Not reached: a black pill, a white number, a gray goal and foot.
    (:test)
    function notReachedIsABlackPillWithWhiteStepsAndGrayGoal(logger as Test.Logger) as Boolean {
        var field = bottomAt(1147, 3110);
        Test.assertEqual(0x000000, field.pill.color);
        Test.assertEqual(0xFFFFFF, field.numberColor);
        Test.assertEqual(0x8C8C8C, field.goalColor);
        Test.assertEqual(0x8C8C8C, field.iconColor);
        return true;
    }

    // Story 30: missing steps are "--" in gray (18 px wide, at 228 - 18 =
    // 210), still with "/ goal" when the goal is known.
    (:test)
    function missingStepsAreGrayDashesWithTheGoal(logger as Test.Logger) as Boolean {
        var field = bottomAt(null, 3110);
        Test.assertEqual("--", field.number);
        Test.assertEqual(0x8C8C8C, field.numberColor);
        Test.assertEqual(210, field.numberX);
        Test.assertEqual("/ 3.110", field.goal);
        Test.assertEqual(233, field.goalX);
        return true;
    }

    // A negative step count is no reading: "--" like a missing one.
    (:test)
    function negativeStepsShowGrayDashes(logger as Test.Logger) as Boolean {
        var field = bottomAt(-5, 3110);
        Test.assertEqual("--", field.number);
        Test.assertEqual(0x8C8C8C, field.numberColor);
        return true;
    }

    // Story 29: goal 0 or missing shows the steps without "/ goal", in the
    // not-reached style.
    (:test)
    function noGoalShowsStepsWithoutGoal(logger as Test.Logger) as Boolean {
        var goals = [0, null] as Array<Number?>;
        for (var i = 0; i < goals.size(); i++) {
            var field = bottomAt(1147, goals[i]);
            Test.assertEqual("1.147", field.number);
            Test.assertEqual(0xFFFFFF, field.numberColor);
            Test.assertEqual("", field.goal);
            Test.assertEqual(175, field.numberX);
            Test.assertEqual(0x000000, field.pill.color);
        }
        return true;
    }

    // Steps and goal both missing: "--" in gray only.
    (:test)
    function stepsAndGoalMissingShowGrayDashesOnly(logger as Test.Logger) as Boolean {
        var field = bottomAt(null, null);
        Test.assertEqual("--", field.number);
        Test.assertEqual(0x8C8C8C, field.numberColor);
        Test.assertEqual("", field.goal);
        Test.assertEqual(210, field.numberX);
        Test.assertEqual((0xE003).toChar().toString(), field.icon);
        Test.assertEqual(140, field.iconX);
        return true;
    }

    // Digits centered on y 340: baseline 340 + 16 / 2 = 348 at 22 px and
    // 340 + 13 / 2 = 346 at 18 px. The goal (Bold 15, cap 11) on y 341:
    // baseline 341 + 5 = 346.
    (:test)
    function stepTextSitsOnItsBaselines(logger as Test.Logger) as Boolean {
        var field = bottomAt(1147, 3110);
        Test.assertEqual(348, field.numberY + GlyphWidths.NUMBER_22_BASE);
        Test.assertEqual(346, field.goalY + GlyphWidths.GOAL_15_BASE);
        Test.assertEqual(346, bottomAt(10000, 11111).numberY + GlyphWidths.NUMBER_18_BASE);
        return true;
    }

    // Story 22: a dot every three digits, with the groups zero-padded.
    (:test)
    function stepsUseADotThousandsSeparator(logger as Test.Logger) as Boolean {
        Test.assertEqual("0", bottomAt(0, null).number);
        Test.assertEqual("999", bottomAt(999, null).number);
        Test.assertEqual("1.000", bottomAt(1000, null).number);
        Test.assertEqual("1.050", bottomAt(1050, null).number);
        Test.assertEqual("1.000.000", bottomAt(1000000, null).number);
        return true;
    }

    // Q13: each accent channel x 0.55, rounded half up. Mint 8E E3 B8 gives
    // 142 x 0.55 = 78.1 -> 4E, 227 x 0.55 = 124.85 -> 7D, 184 x 0.55 = 101.2
    // -> 65.
    (:test)
    function aodColorIsMintDimmedTo55Percent(logger as Test.Logger) as Boolean {
        var aod = aodAt(8, 42);
        Test.assertEqual(0x4E7D65, aod.timeColor);
        Test.assertEqual(0x4E7D65, aod.dateColor);
        Test.assertEqual(0x4E7D65, aod.datePill.color);
        return true;
    }

    // Story 39, Q28: every minute's offset is within +-4 px.
    (:test)
    function aodOffsetsStayWithin4Px(logger as Test.Logger) as Boolean {
        var offsets = aodOffsets();
        for (var m = 0; m < 60; m++) {
            Test.assert(absOf(offsets[m][0]) <= 4);
            Test.assert(absOf(offsets[m][1]) <= 4);
        }
        return true;
    }

    // A fixed cycle of N >= 4 distinct offsets, indexed by the minute modulo
    // N, with N dividing 60 so the hour wraps onto the cycle.
    (:test)
    function aodOffsetsFollowACycleOfAtLeast4DistinctOffsets(logger as Test.Logger) as Boolean {
        var offsets = aodOffsets();
        // The cycle length: the smallest shift that maps every minute's
        // offset onto the offset that many minutes later.
        var n = 1;
        while (n < 60) {
            var repeats = true;
            for (var m = 0; m < 60 && repeats; m++) {
                var other = offsets[(m + n) % 60];
                repeats = offsets[m][0] == other[0] && offsets[m][1] == other[1];
            }
            if (repeats) {
                break;
            }
            n++;
        }
        // n divides 60 by construction: a repeat across the wrap at 60
        // minutes. A cycle that does not divide 60 shows up as fewer than n
        // distinct offsets below.
        Test.assert(n >= 4);
        for (var i = 0; i < n; i++) {
            for (var j = i + 1; j < n; j++) {
                Test.assert(offsets[i][0] != offsets[j][0] || offsets[i][1] != offsets[j][1]);
            }
        }
        return true;
    }

    // Each minute moves the time and date by at least 3 px in x and in y,
    // including from minute 59 back to minute 0.
    (:test)
    function aodOffsetMovesAtLeast3PxEachMinute(logger as Test.Logger) as Boolean {
        var offsets = aodOffsets();
        for (var m = 0; m < 60; m++) {
            assertMovesAtLeast3PxOnBothAxes(offsets[m], offsets[(m + 1) % 60]);
        }
        return true;
    }

    // The wrap at the top of the hour, stated on its own.
    (:test)
    function aodOffsetMovesFromMinute59ToMinute0(logger as Test.Logger) as Boolean {
        var last = aodAt(10, 59);
        var first = aodAt(11, 0);
        assertMovesAtLeast3PxOnBothAxes([last.offsetX, last.offsetY] as Array<Number>,
            [first.offsetX, first.offsetY] as Array<Number>);
        return true;
    }

    // Any 3 consecutive offsets are pairwise distinct and not on one line,
    // so the shift never steps back and forth or along one diagonal. Checked
    // cyclically, including the triples 58-59-0 and 59-0-1.
    (:test)
    function threeConsecutiveAodOffsetsAreDistinctAndNotCollinear(logger as Test.Logger) as Boolean {
        var offsets = aodOffsets();
        for (var m = 0; m < 60; m++) {
            var a = offsets[m];
            var b = offsets[(m + 1) % 60];
            var c = offsets[(m + 2) % 60];
            Test.assert(a[0] != c[0] || a[1] != c[1]);
            Test.assert(a[0] != b[0] || a[1] != b[1]);
            var cross = (b[0] - a[0]) * (c[1] - b[1]) - (b[1] - a[1]) * (c[0] - b[0]);
            Test.assert(cross != 0);
        }
        return true;
    }

    // Story 37: the AOD time keeps the normal time's position and size
    // (08:42 is 4 x 28 + 14 = 126 px wide, from x 208 - 63 = 145; baseline
    // 135 - base 56 = line top 79), moved by the minute's offset.
    (:test)
    function aodTimeSitsWhereTheNormalTimeIsMovedByTheOffset(logger as Test.Logger) as Boolean {
        var aod = aodAt(8, 42);
        Test.assertEqual("08:42", aod.time);
        Test.assertEqual(145 + aod.offsetX, aod.timeX);
        Test.assertEqual(79 + aod.offsetY, aod.timeY);
        return true;
    }

    // Story 37: the AOD date is the normal date text at the normal position
    // ("THU 12" is 67 px wide, from x 208 - 33 = 175; baseline 160 - base 18
    // = line top 142), moved by the minute's offset.
    (:test)
    function aodDateSitsWhereTheNormalDateIsMovedByTheOffset(logger as Test.Logger) as Boolean {
        var aod = aodOnDate("Thu", 5, 12);
        Test.assertEqual("THU 12", aod.date);
        Test.assertEqual(175 + aod.offsetX, aod.dateX);
        Test.assertEqual(142 + aod.offsetY, aod.dateY);
        return true;
    }

    // The AOD date follows the same folding and short forms as the normal
    // date (Q21).
    (:test)
    function aodDateUsesTheVietnameseShortForm(logger as Test.Logger) as Boolean {
        var thu5 = fromCodePoints([0x54, 0x68, 0x1EE9, 0x20, 0x35] as Array<Number>);
        Test.assertEqual("T5 12", aodOnDate(thu5, 5, 12).date);
        return true;
    }

    // Story 38: the pill as a 2 px outline, inset 1 px from the normal pill
    // (160, 140, 96, 28) so its outer edge stays on the pill's edge: (161,
    // 141, 94, 26), radius 13, moved by the minute's offset.
    (:test)
    function aodPillIsA2PxOutlineInset1PxFromTheNormalPill(logger as Test.Logger) as Boolean {
        var aod = aodOnDate("Thu", 5, 12);
        var pill = aod.datePill;
        Test.assertEqual(161 + aod.offsetX, pill.x);
        Test.assertEqual(141 + aod.offsetY, pill.y);
        Test.assertEqual(94, pill.width);
        Test.assertEqual(26, pill.height);
        Test.assertEqual(13, pill.radius);
        Test.assertEqual(2, aod.datePillPen);
        return true;
    }

    // A longer name grows the AOD pill as it grows the normal one:
    // "WEDNESDAY 28" is 125 + 30 = 155 px, a pill of 155 + 2 x 14 = 183 from
    // x 208 - 91 = 117, so the outline is 181 wide from x 118.
    (:test)
    function aodPillFollowsTheNormalPillWidth(logger as Test.Logger) as Boolean {
        var aod = aodOnDate("Wednesday", 4, 28);
        Test.assertEqual(181, aod.datePill.width);
        Test.assertEqual(118 + aod.offsetX, aod.datePill.x);
        return true;
    }
}
