import Toybox.Graphics;
import Toybox.Lang;

// Paints a FaceModel frame as-is. No display rules live here.
module Renderer {
    // A full high-power frame. The screen is not guaranteed to keep its
    // previous contents, so every call repaints everything.
    function paint(dc as Dc, frame as Frame, fonts as Fonts) as Void {
        clear(dc);

        dc.setColor(frame.backgroundColor, frame.backgroundColor);
        dc.fillCircle(Layout.CENTER_X, Layout.CENTER_Y, Layout.DISC_RADIUS);

        var w = Layout.WELL;
        dc.setColor(frame.wellColor, frame.wellColor);
        dc.fillRoundedRectangle(Layout.BAND_X - w, Layout.BAND_Y - w,
            Layout.BAND_W + 2 * w, Layout.BAND_H + 2 * w, Layout.BAND_RADIUS + w);

        dc.setColor(frame.timeBandColor, frame.timeBandColor);
        dc.fillRoundedRectangle(Layout.BAND_X, Layout.BAND_Y,
            Layout.BAND_W, Layout.BAND_H, Layout.BAND_RADIUS);

        // FaceModel places the time by its measured width and the font's base.
        dc.setColor(frame.timeColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(frame.timeX, frame.timeY, fonts.time, frame.time,
            Graphics.TEXT_JUSTIFY_LEFT);
    }

    // The whole screen black.
    function clear(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
    }
}
