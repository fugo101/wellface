import Toybox.Graphics;
import Toybox.Lang;

// Paints FaceModel output as-is. No display rules live here.
//
// The static layer is drawn once into a full-color buffer and copied to the
// screen on every high-power update. It depends on the theme and the field
// mapping (the metric each round field shows decides its track), so a new
// one comes with every applied face config (setStatic) and the buffer is
// repainted once then. The face is started again after a widget opened in
// full, so the buffer is rebuilt then too; a return from the widget loop
// only hides and shows the view and keeps it (docs/build.md, "Timing
// build").
class Renderer {
    private var _layer as StaticLayer = new StaticLayer();
    private var _notches as Array<Line> = [] as Array<Line>;
    private var _fonts as Fonts;
    // The reference and the bitmap it returned. Holding the bitmap keeps it
    // locked in the graphics pool, so it is drawn once and never purged
    // (Garmin's graphics pool guide).
    private var _reference as BufferedBitmapReference?;
    private var _bitmap as BufferedBitmap?;

    // Nothing is painted before the first setStatic.
    function initialize(fonts as Fonts) {
        _fonts = fonts;
    }

    // The static layer and bezel notches of a newly applied face config. The
    // buffer is kept and repainted once, on the next high-power update.
    function setStatic(layer as StaticLayer, notches as Array<Line>) as Void {
        _layer = layer;
        _notches = notches;
        // Dropping the bitmap makes staticBitmap get it again from the
        // reference and paint the new layer into it.
        _bitmap = null;
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

        // The notches go over the progress so the quarters stay readable,
        // and the head dot over both.
        drawArc(dc, frame.bezelProgress);
        for (var i = 0; i < _notches.size(); i++) {
            drawLine(dc, _notches[i]);
        }
        var head = frame.bezelHead;
        if (head != null) {
            fillCircle(dc, head);
        }

        var lit = frame.batteryLit;
        for (var i = 0; i < lit.size(); i++) {
            drawArc(dc, lit[i]);
        }

        paintField(dc, frame.leftField);
        paintField(dc, frame.centerField);
        paintField(dc, frame.rightField);
        paintBottomField(dc, frame.bottomField);

        // FaceModel places the time by its measured width and the font's base.
        dc.setColor(frame.timeColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(frame.timeX, frame.timeY, _fonts.get(FONT_TIME), frame.time,
            Graphics.TEXT_JUSTIFY_LEFT);

        // The pill's width follows the text, so it is not in the static layer.
        fillRoundedRect(dc, frame.datePill);
        var dateFont = _fonts.get(FONT_DATE);
        dc.setColor(frame.weekdayColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(frame.dateX, frame.dateY, dateFont, frame.weekday, Graphics.TEXT_JUSTIFY_LEFT);
        dc.setColor(frame.dayMonthColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(frame.dayMonthX, frame.dateY, dateFont, frame.dayMonth,
            Graphics.TEXT_JUSTIFY_LEFT);
    }

    // A field's arcs, their round caps and the gauge's end dot, its icon and
    // number, over its well and track in the static layer.
    private function paintField(dc as Dc, field as FieldFrame) as Void {
        for (var i = 0; i < field.arcs.size(); i++) {
            drawArc(dc, field.arcs[i]);
        }
        for (var i = 0; i < field.caps.size(); i++) {
            fillCircle(dc, field.caps[i]);
        }
        var dot = field.dot;
        if (dot != null) {
            fillCircle(dc, dot);
        }
        dc.setColor(field.iconColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(field.iconX, field.iconY, _fonts.get(FONT_ICONS), field.icon,
            Graphics.TEXT_JUSTIFY_LEFT);
        dc.setColor(field.numberColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(field.numberX, field.numberY, _fonts.get(field.numberFont), field.number,
            Graphics.TEXT_JUSTIFY_LEFT);
    }

    // The pill (its own well), then the icon if shown, the number and
    // "/ goal" if any.
    private function paintBottomField(dc as Dc, field as BottomFieldFrame) as Void {
        fillRoundedRect(dc, field.pill);
        if (field.icon.length() > 0) {
            dc.setColor(field.iconColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(field.iconX, field.iconY, _fonts.get(FONT_ICONS), field.icon,
                Graphics.TEXT_JUSTIFY_LEFT);
        }
        dc.setColor(field.numberColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(field.numberX, field.numberY, _fonts.get(field.numberFont), field.number,
            Graphics.TEXT_JUSTIFY_LEFT);
        if (field.goal.length() > 0) {
            dc.setColor(field.goalColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(field.goalX, field.goalY, _fonts.get(FONT_GOAL_15), field.goal,
                Graphics.TEXT_JUSTIFY_LEFT);
        }
    }

    // An Always On frame: no buffers, only the filled time, the date pill's
    // outline (the pill filled, its inside filled black again) and the date
    // text on black.
    function paintAod(dc as Dc, frame as AodFrame) as Void {
        clear(dc);
        dc.setColor(frame.timeColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(frame.timeX, frame.timeY, _fonts.get(FONT_TIME), frame.time,
            Graphics.TEXT_JUSTIFY_LEFT);

        fillRoundedRect(dc, frame.datePill);
        fillRoundedRect(dc, frame.datePillInner);

        dc.setColor(frame.dateColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(frame.dateX, frame.dateY, _fonts.get(FONT_DATE), frame.date,
            Graphics.TEXT_JUSTIFY_LEFT);
    }

    // The whole screen black.
    private function clear(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
    }

    // The buffer holding the static layer, drawn when it is first created and
    // after each setStatic.
    // Null if the graphics pool has no room for it. BufferedBitmap.isCached()
    // is not asked: it only says whether get() restored a released bitmap
    // from the pool, and stays false on a bitmap the face keeps holding, which
    // made every update repaint the layer (ticket settings-ready 01).
    private function staticBitmap(width as Number, height as Number) as BufferedBitmap? {
        var bitmap = _bitmap;
        if (bitmap != null) {
            return bitmap;
        }
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

    // Everything that depends only on the face config (its theme and field
    // mapping), back to front.
    private function paintStatic(dc as Dc, layer as StaticLayer) as Void {
        Timing.start(TIMING_STATIC);
        clear(dc);
        drawArc(dc, layer.bezelTrack);

        dc.setColor(layer.backgroundColor, layer.backgroundColor);
        dc.fillCircle(Layout.CENTER_X, Layout.CENTER_Y, Layout.DISC_RADIUS);

        fillRoundedRect(dc, layer.timeBandRim);
        for (var i = 0; i < layer.fieldRims.size(); i++) {
            fillCircle(dc, layer.fieldRims[i]);
        }
        fillRoundedRect(dc, layer.bottomFieldRim);

        drawArc(dc, layer.batteryWell);
        for (var i = 0; i < layer.batteryCaps.size(); i++) {
            fillCircle(dc, layer.batteryCaps[i]);
        }
        for (var i = 0; i < layer.batteryTrack.size(); i++) {
            drawArc(dc, layer.batteryTrack[i]);
        }

        fillRoundedRect(dc, layer.timeBandWell);
        fillRoundedRect(dc, layer.timeBand);

        for (var i = 0; i < layer.fieldWells.size(); i++) {
            fillCircle(dc, layer.fieldWells[i]);
        }
        for (var i = 0; i < layer.fieldTracks.size(); i++) {
            drawArc(dc, layer.fieldTracks[i]);
        }
        for (var i = 0; i < layer.fieldTrackCaps.size(); i++) {
            fillCircle(dc, layer.fieldTrackCaps[i]);
        }
        Timing.stop(TIMING_STATIC);
    }

    private function fillCircle(dc as Dc, circle as Circle) as Void {
        dc.setColor(circle.color, circle.color);
        dc.fillCircle(circle.x, circle.y, circle.radius);
    }

    private function drawLine(dc as Dc, line as Line) as Void {
        dc.setColor(line.color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(line.pen);
        dc.drawLine(line.x1, line.y1, line.x2, line.y2);
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
