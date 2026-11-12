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
    function frameOnDate(weekdayName as String?, weekdayNumber as Number, day as Number) as Frame {
        var snapshot = new Snapshot(8, 42);
        snapshot.weekdayName = weekdayName;
        snapshot.weekdayNumber = weekdayNumber;
        snapshot.day = day;
        return FaceModel.compute(snapshot, Themes.mint());
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
        var wells = mintLayer().fieldWells;
        Test.assertEqual(1, wells.size());
        Test.assertEqual(208, wells[0].x);
        Test.assertEqual(246, wells[0].y);
        Test.assertEqual(66, wells[0].radius);
        Test.assertEqual(0x000000, wells[0].color);
        return true;
    }

    // The gauge track is a full circle in the gauge-track color, exactly
    // under the gauge (same center, radius and pen).
    (:test)
    function centerGaugeTrackIsAFullCircleUnderTheGauge(logger as Test.Logger) as Boolean {
        var tracks = mintLayer().gaugeTracks;
        Test.assertEqual(1, tracks.size());
        var track = tracks[0];
        var gauge = gaugeOf(centerAt(100));
        Test.assertEqual(360, track.sweep);
        Test.assertEqual(0x2E3330, track.color);
        Test.assertEqual(gauge.x, track.x);
        Test.assertEqual(gauge.y, track.y);
        Test.assertEqual(gauge.radius, track.radius);
        Test.assertEqual(gauge.pen, track.pen);
        return true;
    }
}
