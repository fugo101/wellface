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
        Test.assertEqual("THU 5 12", dateOf(fromCodePoints([0x54, 0x68, 0x1EE9, 0x20, 0x35]), 5, 12));
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
        Test.assertEqual("THU 5 12", dateOf(name, 5, 12));
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
}
