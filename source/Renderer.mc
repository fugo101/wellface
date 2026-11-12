import Toybox.Graphics;
import Toybox.Lang;

// Paints FaceModel output as-is. No display rules live here.
//
// The static layer is drawn once into a full-color buffer and copied to the
// screen on every high-power update. The face is started again on every
// return from a widget, so the buffer is rebuilt then too.
class Renderer {
    private var _layer as StaticLayer;
    private var _fonts as Fonts;
    // The reference and the bitmap it returned. Holding the bitmap keeps it
    // locked in the graphics pool; it is drawn again if it was purged anyway.
    private var _reference as BufferedBitmapReference?;
    private var _bitmap as BufferedBitmap?;

    function initialize(layer as StaticLayer, fonts as Fonts) {
        _layer = layer;
        _fonts = fonts;
    }

    // A full high-power frame. The screen is not guaranteed to keep its
    // previous contents, so every call repaints everything.
    function paint(dc as Dc, frame as Frame) as Void {
        var bitmap = staticBitmap(dc.getWidth(), dc.getHeight());
        if (bitmap != null) {
            dc.drawBitmap(0, 0, bitmap);
        } else {
            // No room in the graphics pool: draw the layer straight on screen.
            paintStatic(dc, _layer);
        }

        var lit = frame.batteryLit;
        for (var i = 0; i < lit.size(); i++) {
            drawArc(dc, lit[i]);
        }

        // FaceModel places the time by its measured width and the font's base.
        dc.setColor(frame.timeColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(frame.timeX, frame.timeY, _fonts.time, frame.time,
            Graphics.TEXT_JUSTIFY_LEFT);

        // The pill's width follows the text, so it is not in the static layer.
        fillRoundedRect(dc, frame.datePill);
        dc.setColor(frame.dateColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(frame.dateX, frame.dateY, _fonts.date, frame.date,
            Graphics.TEXT_JUSTIFY_LEFT);
    }

    // The whole screen black.
    function clear(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
    }

    // The buffer holding the static layer, drawn if it is new or was purged.
    // Null if the graphics pool has no room for it.
    private function staticBitmap(width as Number, height as Number) as BufferedBitmap? {
        var bitmap = _bitmap;
        if (bitmap != null && bitmap.isCached()) {
            return bitmap;
        }
        _bitmap = null;
        try {
            var reference = _reference;
            if (reference == null) {
                reference = Graphics.createBufferedBitmap({ :width => width, :height => height });
                _reference = reference;
            }
            bitmap = reference.get() as BufferedBitmap?;
        } catch (e instanceof Graphics.OutOfGraphicsMemoryException) {
            return null;
        }
        if (bitmap == null) {
            return null;
        }
        var bufferDc = bitmap.getDc();
        bufferDc.setAntiAlias(true);
        paintStatic(bufferDc, _layer);
        _bitmap = bitmap;
        return bitmap;
    }

    // Everything that depends only on the theme, back to front.
    private function paintStatic(dc as Dc, layer as StaticLayer) as Void {
        clear(dc);
        drawArc(dc, layer.bezelTrack);

        dc.setColor(layer.backgroundColor, layer.backgroundColor);
        dc.fillCircle(Layout.CENTER_X, Layout.CENTER_Y, Layout.DISC_RADIUS);

        drawArc(dc, layer.batteryWell);
        for (var i = 0; i < layer.batteryCaps.size(); i++) {
            var cap = layer.batteryCaps[i];
            dc.setColor(cap.color, cap.color);
            dc.fillCircle(cap.x, cap.y, cap.radius);
        }
        for (var i = 0; i < layer.batteryTrack.size(); i++) {
            drawArc(dc, layer.batteryTrack[i]);
        }

        var w = Layout.WELL;
        dc.setColor(layer.wellColor, layer.wellColor);
        dc.fillRoundedRectangle(Layout.BAND_X - w, Layout.BAND_Y - w,
            Layout.BAND_W + 2 * w, Layout.BAND_H + 2 * w, Layout.BAND_RADIUS + w);

        dc.setColor(layer.timeBandColor, layer.timeBandColor);
        dc.fillRoundedRectangle(Layout.BAND_X, Layout.BAND_Y,
            Layout.BAND_W, Layout.BAND_H, Layout.BAND_RADIUS);
    }

    private function fillRoundedRect(dc as Dc, rect as RoundedRect) as Void {
        dc.setColor(rect.color, rect.color);
        dc.fillRoundedRectangle(rect.x, rect.y, rect.width, rect.height, rect.radius);
    }

    // One arc in the arc contract. Sweep 0 draws nothing; for 360, start
    // equals end, which drawArc draws as a full circle.
    private function drawArc(dc as Dc, arc as Arc) as Void {
        if (arc.sweep == 0) {
            return;
        }
        dc.setColor(arc.color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(arc.pen);
        dc.drawArc(arc.x, arc.y, arc.radius, Graphics.ARC_CLOCKWISE, arc.start, arc.end);
    }
}
