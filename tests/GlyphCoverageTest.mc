import Toybox.Lang;
import Toybox.Test;

// Every string the face can print exists in the font it is drawn in, so no
// glyph silently measures as zero width (a glyph missing from a font is
// measured as 0 by FaceModel.textWidth and drawn as nothing).
//
// The value ranges are test inputs, not clamps: missing, 0, stress and Body
// Battery up to 100, heart rate up to 250, steps and the step goal up to
// 199.999. Every valid field and metric pair (Q40) is covered: stress, Body
// Battery and heart rate in each round field, steps in the bottom field
// (the bezel ring draws no text).
//
// Until a face config can put any metric in any field (ticket 03), the
// round and bottom fields are built with FaceModel.roundField and
// bottomField directly, and the date with dateText and foldChar; move them
// to the entry points then.
(:test)
module GlyphCoverageTest {
    // Fails with the string, the character and the font when a character
    // is missing.
    function assertDrawable(text as String, font as FontId, what as String) as Void {
        var entry = FontCatalog.entry(font);
        var chars = text.toCharArray();
        for (var i = 0; i < chars.size(); i++) {
            if (!entry.hasGlyph(chars[i])) {
                Test.assertMessage(false, what + " \"" + text + "\": U+"
                    + chars[i].toNumber().format("%04X") + " is not in " + entry.name);
            }
        }
    }

    function assertField(field as FieldFrame, what as String) as Void {
        assertDrawable(field.icon, FONT_ICONS, what + " icon");
        assertDrawable(field.number, field.numberFont, what + " number");
    }

    function assertBottomField(field as BottomFieldFrame, what as String) as Void {
        assertDrawable(field.icon, FONT_ICONS, what + " icon");
        assertDrawable(field.number, field.numberFont, what + " number");
        assertDrawable(field.goal, FONT_GOAL_15, what + " goal");
    }

    function snapshotWith(metric as Metric, value as Number?) as Snapshot {
        var s = new Snapshot(8, 42);
        // Zones, so heart rate also lights its segments.
        s.heartRateZones = [96, 115, 134, 154, 173, 192] as Array<Number>;
        s.setValue(metric, value);
        return s;
    }

    // Each round field showing `metric`, from missing up to `max`.
    function assertRoundFields(metric as Metric, max as Number) as Void {
        var fields = [Layout.leftField(), Layout.centerField(), Layout.rightField()]
            as Array<RoundField>;
        var theme = Themes.mint();
        for (var f = 0; f < fields.size(); f++) {
            assertField(FaceModel.roundField(fields[f], metric, snapshotWith(metric, null), theme),
                "missing in field " + f);
            for (var value = 0; value <= max; value++) {
                assertField(FaceModel.roundField(fields[f], metric, snapshotWith(metric, value),
                    theme), "" + value + " in field " + f);
            }
        }
    }

    (:test)
    function stressInEveryRoundFieldIsDrawable(logger as Test.Logger) as Boolean {
        assertRoundFields(METRIC_STRESS, 100);
        return true;
    }

    (:test)
    function bodyBatteryInEveryRoundFieldIsDrawable(logger as Test.Logger) as Boolean {
        assertRoundFields(METRIC_BODY_BATTERY, 100);
        return true;
    }

    (:test)
    function heartRateInEveryRoundFieldIsDrawable(logger as Test.Logger) as Boolean {
        assertRoundFields(METRIC_HEART_RATE, 250);
        return true;
    }

    // Steps and goals with every digit count from 1 to 6, at and around
    // each power of ten, plus a spread up to 199.999.
    function stepValues() as Array<Number> {
        var values = [0, 199999] as Array<Number>;
        for (var p = 1; p <= 100000; p *= 10) {
            values.add(p - 1);
            values.add(p);
            values.add(p + 1);
        }
        for (var v = 7; v < 200000; v += 4999) {
            values.add(v);
        }
        return values;
    }

    (:test)
    function stepsInTheBottomFieldAreDrawable(logger as Test.Logger) as Boolean {
        var values = stepValues();
        var goals = stepValues();
        goals.add(3110);
        var theme = Themes.mint();
        for (var g = -1; g < goals.size(); g++) {
            var goal = g < 0 ? null : goals[g];
            var goalText = goal == null ? "missing" : goal.toString();
            assertBottomField(FaceModel.bottomField(METRIC_STEPS, null, goal, theme),
                "missing steps, goal " + goalText);
            for (var i = 0; i < values.size(); i++) {
                assertBottomField(FaceModel.bottomField(METRIC_STEPS, values[i], goal, theme),
                    "" + values[i] + " steps, goal " + goalText);
            }
        }
        return true;
    }

    // Every time of day, normal and Always On.
    (:test)
    function everyTimeIsDrawable(logger as Test.Logger) as Boolean {
        var config = FaceModel.resolve(FaceConfigs.defaultConfig());
        for (var minute = 0; minute < 24 * 60; minute++) {
            var aod = FaceModel.computeAod(new Snapshot(minute / 60, minute % 60), config);
            assertDrawable(aod.time, FONT_TIME, "time");
        }
        var frame = FaceModel.compute(new Snapshot(23, 59), config);
        assertDrawable(frame.time, FONT_TIME, "time");
        return true;
    }

    // Every second, in the font the seconds are drawn in (the 26 px number
    // font, Q41): a missing glyph would be drawn as nothing.
    (:test)
    function everySecondIsDrawable(logger as Test.Logger) as Boolean {
        var config = FaceModel.resolve(FaceConfigs.defaultConfig());
        Test.assertEqual(FONT_NUMBER_26, FaceModel.SECONDS_FONT);
        for (var second = 0; second < 60; second++) {
            var s = new Snapshot(8, 42);
            s.second = second;
            var seconds = FaceModel.compute(s, config).seconds;
            Test.assertEqual(2, seconds.length());
            assertDrawable(seconds, FaceModel.SECONDS_FONT, "seconds");
        }
        return true;
    }

    // Every character a weekday name can fold to is in the date font, so
    // every folded name is drawable: Basic Latin to Latin Extended B, the
    // combining marks and Vietnamese (Latin Extended Additional).
    (:test)
    function everyFoldedWeekdayCharacterIsDrawable(logger as Test.Logger) as Boolean {
        var ranges = [[0x0020, 0x024F], [0x0300, 0x036F], [0x1E00, 0x1EFF]]
            as Array<Array<Number> >;
        for (var r = 0; r < ranges.size(); r++) {
            for (var c = ranges[r][0]; c <= ranges[r][1]; c++) {
                var folded = FaceModel.foldChar(c);
                if (folded != null) {
                    assertDrawable(folded.toString(), FONT_DATE,
                        "U+" + c.format("%04X") + " folded");
                }
            }
        }
        return true;
    }

    // Every date the pill can show: the English fallback (no name) and
    // a few names for every weekday, with every day and every month.
    (:test)
    function everyDateIsDrawable(logger as Test.Logger) as Boolean {
        var names = [null, "Thu 8", "CN", "T2", "Wednesday"] as Array<String?>;
        for (var weekday = 1; weekday <= 7; weekday++) {
            for (var n = 0; n < names.size(); n++) {
                var s = new Snapshot(8, 42);
                s.weekdayNumber = weekday;
                s.weekdayName = names[n];
                for (var day = 1; day <= 31; day++) {
                    s.day = day;
                    assertDrawable(FaceModel.dateText(s), FONT_DATE, "date");
                }
                s.day = 28;
                for (var month = 1; month <= 12; month++) {
                    s.month = month;
                    assertDrawable(FaceModel.dateText(s), FONT_DATE, "date");
                }
            }
        }
        // "Thứ 2" ... "Thứ 7" as the watch returns them, and "Chủ nhật".
        for (var digit = 2; digit <= 7; digit++) {
            var s = new Snapshot(8, 42);
            s.weekdayName = "Th" + (0x1EE9).toChar() + " " + digit;
            assertDrawable(FaceModel.dateText(s), FONT_DATE, "date");
        }
        var sunday = new Snapshot(8, 42);
        sunday.weekdayName = "Ch" + (0x1EE7).toChar() + " nh" + (0x1EAD).toChar() + "t";
        assertDrawable(FaceModel.dateText(sunday), FONT_DATE, "date");
        return true;
    }

    // Each font's glyph set and width table hold the same glyphs.
    (:test)
    function everyGlyphHasAWidth(logger as Test.Logger) as Boolean {
        var entries = FontCatalog.entries();
        for (var i = 0; i < entries.size(); i++) {
            var entry = entries[i];
            var glyphs = entry.glyphs.toCharArray();
            Test.assertEqualMessage(glyphs.size(), entry.widths.size(), entry.name);
            for (var g = 0; g < glyphs.size(); g++) {
                Test.assertMessage(entry.widths.hasKey(glyphs[g]),
                    entry.name + " has no width for U+" + glyphs[g].toNumber().format("%04X"));
            }
        }
        return true;
    }

    // A glyph the font lacks is caught (the test's own check).
    (:test)
    function aMissingGlyphIsDetected(logger as Test.Logger) as Boolean {
        Test.assert(!FontCatalog.entry(FONT_NUMBER_48).hasGlyph('.'));
        Test.assert(!FontCatalog.entry(FONT_TIME).hasGlyph('-'));
        Test.assert(FontCatalog.entry(FONT_NUMBER_22).hasGlyph('.'));
        Test.assert(FontCatalog.entry(FONT_ICONS).hasGlyph(FontCatalog.ICON_HEART.toChar()));
        return true;
    }
}
