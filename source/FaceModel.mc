import Toybox.Lang;

// The data a frame is computed from. Built by the view from the watch's
// clock and sensors; FaceModel never reads them itself.
class Snapshot {
    // 0-23, whatever the watch's 12/24 h setting is (Q22).
    public var hour as Number;
    public var minute as Number;

    function initialize(hour as Number, minute as Number) {
        self.hour = hour;
        self.minute = minute;
    }
}

// What to draw: every string and color the renderer needs. FaceModel fills
// in every field; the defaults only exist to satisfy the type checker.
class Frame {
    public var time as String = "";
    // Width of the time in the time font, from its glyph-width table.
    public var timeWidth as Number = 0;
    // Top-left corner to draw the time from (left-justified, line top).
    public var timeX as Number = 0;
    public var timeY as Number = 0;
    public var timeColor as Number = 0;
    public var timeBandColor as Number = 0;
    public var backgroundColor as Number = 0;
    public var wellColor as Number = 0;

    function initialize() {
    }
}

// Pure display rules: no sensor, graphics or resource dependencies.
// This is the face's only test seam.
module FaceModel {
    function compute(snapshot as Snapshot, theme as Theme) as Frame {
        var frame = new Frame();
        frame.time = formatTime(snapshot.hour, snapshot.minute);
        frame.timeWidth = textWidth(frame.time, GlyphWidths.TIME);
        frame.timeX = Layout.TIME_CENTER_X - frame.timeWidth / 2;
        frame.timeY = Layout.TIME_BASELINE_Y - GlyphWidths.TIME_BASE;
        frame.timeColor = theme.ink;
        frame.timeBandColor = theme.accent;
        frame.backgroundColor = theme.background;
        frame.wellColor = theme.ink;
        return frame;
    }

    // Always 24 h with a leading zero, for example "08:42" (Q22).
    function formatTime(hour as Number, minute as Number) as String {
        return hour.format("%02d") + ":" + minute.format("%02d");
    }

    // Width of text drawn in a generated font: the sum of its glyphs'
    // xadvance values. A glyph missing from the table counts as 0.
    function textWidth(text as String, widths as Dictionary<Char, Number>) as Number {
        var total = 0;
        var chars = text.toCharArray();
        for (var i = 0; i < chars.size(); i++) {
            var w = widths[chars[i]];
            if (w != null) {
                total += w;
            }
        }
        return total;
    }
}
