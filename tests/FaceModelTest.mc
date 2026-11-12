import Toybox.Lang;
import Toybox.Test;

// Every declaration here is (:test) so no test code reaches a release build.
(:test)
module FaceModelTest {

    // Helpers stay unannotated: the (:test) module keeps them out of release builds.
    function frameAt(hour as Number, minute as Number) as Frame {
        return FaceModel.compute(new Snapshot(hour, minute), Themes.mint());
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
        Test.assertEqual(0x8EE3B8, frame.timeBandColor);
        Test.assertEqual(0x000000, frame.timeColor);
        return true;
    }

    (:test)
    function mintBackgroundDiscIsDarkGreyInBlackWells(logger as Test.Logger) as Boolean {
        var frame = frameAt(8, 42);
        Test.assertEqual(0x1A1D1B, frame.backgroundColor);
        Test.assertEqual(0x000000, frame.wellColor);
        return true;
    }
}
