import Toybox.Graphics;
import Toybox.Lang;

// Paints a FaceModel frame as-is. No display rules live here.
module Renderer {
    // A full high-power frame. The screen is not guaranteed to keep its
    // previous contents, so every call repaints everything.
    function paint(dc as Dc, frame as Frame) as Void {
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

        // Tracer bullet: a system font, centered in the band. Ticket 03
        // replaces it with the generated time font placed on its baseline.
        dc.setColor(frame.timeColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(Layout.CENTER_X, Layout.BAND_Y + Layout.BAND_H / 2,
            Graphics.FONT_NUMBER_MILD, frame.time,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // The whole screen black.
    function clear(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
    }
}
