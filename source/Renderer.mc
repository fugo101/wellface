import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;

// Paints FaceModel output as-is. No display rules live here.
//
// Two full-screen buffers (Q44, ticket 08). The static layer is drawn once
// into the first. It depends on the theme and the field mapping (the metric
// each round field shows decides its track), so a new one comes with every
// applied face config (setStatic) and the buffer is repainted once then.
// The minute layer is the second: the static layer and every frame part
// that changes at most once a minute, rebuilt only when one of them changes
// (FaceModel.minuteLayerChanged), after a new static layer, or when the
// buffer is new. Each second it is copied to the screen and only the parts
// that change every second (the seconds, the field showing heart rate) are drawn
// over it.
//
// Drawing into a buffer is about 2.5 times slower than drawing on the
// screen on the FR265 (ticket 08), so a frame whose minute layer is stale
// (a wake, a new minute, a face start) is first drawn straight on the
// screen, as fast as a full repaint, and the buffers are painted on the
// updates after it, at most one per update. The face is started again
// after a widget opened in full, so both buffers are rebuilt then; a return
// from the widget loop only hides and shows the view and keeps them
// (docs/build.md, "Timing build"). When the graphics pool has no room for a
// buffer, every update is a full repaint (logged once).
class Renderer {
    private var _layer as StaticLayer = new StaticLayer();
    private var _fonts as Fonts;
    // Each buffer's reference and the bitmap it returned. Holding the
    // bitmap keeps it locked in the graphics pool, so it is never purged
    // (Garmin's graphics pool guide).
    private var _reference as BufferedBitmapReference?;
    private var _bitmap as BufferedBitmap?;
    private var _minuteReference as BufferedBitmapReference?;
    private var _minuteBitmap as BufferedBitmap?;
    // The frame parts (FramePart bits) that change every second and those
    // that change at most once a minute (FaceModel.everySecondParts,
    // everyMinuteParts), for the applied face config.
    private var _everySecond as Number = 0;
    private var _everyMinute as Number = 0;
    // The minute layer no longer matches the frame (or there is none yet).
    private var _minuteStale as Boolean = true;
    // A stale frame was drawn straight on the screen; the buffers are
    // painted from the next update on.
    private var _rebuildDue as Boolean = false;
    // A full repaint replaced the minute layer since it last worked; logged
    // once each time it starts.
    private var _fallingBack as Boolean = false;
    // The graphics pool had no room for a buffer: full repaints, without
    // asking for a buffer again until the next wake, show or face config.
    private var _noRoom as Boolean = false;

    // Always repaint in full, as when the graphics pool has no room for the
    // minute layer (the capture face forces it to compare the two).
    public var forceFullRepaint as Boolean = false;

    // Nothing is painted before the first setStatic.
    function initialize(fonts as Fonts) {
        _fonts = fonts;
    }

    // The static layer of a newly applied face config, and the frame parts
    // that change every second and at most once a minute for it. Both
    // buffers are kept and repainted on the next high-power updates.
    function setStatic(layer as StaticLayer, everySecond as Number, everyMinute as Number)
            as Void {
        _layer = layer;
        _everySecond = everySecond;
        _everyMinute = everyMinute;
        // Dropping the bitmap makes staticBitmap get it again from the
        // reference and paint the new layer into it.
        _bitmap = null;
        _minuteStale = true;
        _rebuildDue = false;
        _noRoom = false;
    }

    // The next frame is to be shown at once: the first after a wake or a
    // show, or one while the face sleeps (no per-second updates follow, so
    // a rebuild would be wasted). If the minute layer is stale, that frame
    // is drawn straight on the screen even when a rebuild was already due.
    // A buffer the pool had no room for is asked for again.
    function showAtOnce() as Void {
        _rebuildDue = false;
        _noRoom = false;
    }

    // Whether the next frame is copied from the minute layer, which is then
    // built and current (the capture face waits for it).
    function minuteLayerReady() as Boolean {
        return !_minuteStale && _minuteBitmap != null && !forceFullRepaint;
    }

    // A high-power frame. `minuteChanged` says whether the changes since the
    // previous one made a part of the minute layer stale
    // (FaceModel.minuteLayerChanged). The screen is not guaranteed to keep
    // its previous contents, so the screen itself is always repainted in
    // full.
    function paint(dc as Dc, frame as Frame, minuteChanged as Boolean) as Void {
        if (minuteChanged) {
            _minuteStale = true;
        }
        var width = dc.getWidth();
        var height = dc.getHeight();
        if (forceFullRepaint) {
            fallBack("minute layer (forced)");
        } else if (!_minuteStale) {
            copyMinuteLayer(dc, frame);
            return;
        } else if (!_rebuildDue) {
            // Shown at once, straight on the screen; the buffers follow.
            _rebuildDue = true;
            var held = _bitmap;
            if (held != null) {
                dc.drawBitmap(0, 0, held);
            } else {
                paintStatic(dc, _layer);
            }
            paintParts(dc, frame, _everySecond | _everyMinute);
            return;
        } else if (_noRoom) {
            // A full repaint, as on the update the pool had no room.
        } else if (_bitmap == null) {
            // The static buffer this update, the minute layer on the next.
            if (staticBitmap(width, height) == null) {
                noRoom("static buffer");
            }
        } else if (minuteBitmap(width, height) != null) {
            rebuildMinuteLayer(frame);
            copyMinuteLayer(dc, frame);
            return;
        } else {
            noRoom("minute layer");
        }
        // A full repaint: the static layer from its buffer when there is
        // one (the forced one asks for it), then every part.
        var bitmap = _noRoom ? _bitmap : staticBitmap(width, height);
        if (bitmap != null) {
            dc.drawBitmap(0, 0, bitmap);
        } else {
            paintStatic(dc, _layer);
        }
        paintParts(dc, frame, _everySecond | _everyMinute);
    }

    // The minute layer to the screen, then the every-second parts.
    private function copyMinuteLayer(dc as Dc, frame as Frame) as Void {
        dc.drawBitmap(0, 0, _minuteBitmap as BufferedBitmap);
        paintParts(dc, frame, _everySecond);
    }

    // The static layer and the minute parts into the minute buffer.
    private function rebuildMinuteLayer(frame as Frame) as Void {
        Timing.start(TIMING_MINUTE);
        var minuteDc = (_minuteBitmap as BufferedBitmap).getDc();
        minuteDc.setAntiAlias(true);
        minuteDc.drawBitmap(0, 0, _bitmap as BufferedBitmap);
        paintParts(minuteDc, frame, _everyMinute);
        _minuteStale = false;
        _rebuildDue = false;
        _fallingBack = false;
        Timing.stop(TIMING_MINUTE);
    }

    // No room in the graphics pool for a buffer: full repaints until the
    // next wake, show or face config.
    private function noRoom(what as String) as Void {
        _noRoom = true;
        fallBack(what);
    }

    // Logs the start of a full repaint in place of the minute layer.
    private function fallBack(what as String) as Void {
        if (!_fallingBack) {
            _fallingBack = true;
            System.println("wellface: no room for the " + what + ", full repaint");
        }
    }

    // The frame parts in `parts` (FramePart bits), back to front. Parts that
    // change every second never overlap a later part, so drawing them after
    // the minute content gives the same pixels as drawing all in this order.
    private function paintParts(dc as Dc, frame as Frame, parts as Number) as Void {
        if ((parts & PART_BEZEL_RING) != 0) {
            // The lit bezel ticks over the unlit ones in the buffer, the
            // lead tick last.
            drawLines(dc, frame.bezelLit);
            var lead = frame.bezelLead;
            if (lead != null) {
                drawLine(dc, lead);
            }
        }
        if ((parts & PART_BATTERY) != 0) {
            var lit = frame.batteryLit;
            for (var i = 0; i < lit.size(); i++) {
                drawArc(dc, lit[i]);
            }
        }
        if ((parts & PART_LEFT) != 0) {
            paintField(dc, frame.leftField);
        }
        if ((parts & PART_CENTER) != 0) {
            paintField(dc, frame.centerField);
        }
        if ((parts & PART_RIGHT) != 0) {
            paintField(dc, frame.rightField);
        }
        if ((parts & PART_BOTTOM) != 0) {
            paintBottomField(dc, frame.bottomField);
        }
        if ((parts & PART_TIME) != 0) {
            // FaceModel places the time by its measured width and the
            // font's base.
            drawText(dc, frame.timeX, frame.timeY, FONT_TIME, frame.time, frame.timeColor);
        }
        if ((parts & PART_SECONDS) != 0) {
            // The seconds, at a fixed place after the minutes (high power
            // only: the Always On frame has none).
            drawText(dc, frame.secondsX, frame.secondsY, FaceModel.SECONDS_FONT, frame.seconds,
                frame.secondsColor);
        }
        if ((parts & PART_DATE) != 0) {
            // The pill's width follows the text, so it is not in the static
            // layer.
            fillRoundedRect(dc, frame.datePill);
            drawText(dc, frame.dateX, frame.dateY, FONT_DATE, frame.weekday, frame.weekdayColor);
            drawText(dc, frame.dayMonthX, frame.dateY, FONT_DATE, frame.dayMonth,
                frame.dayMonthColor);
        }
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
        drawText(dc, field.iconX, field.iconY, FONT_ICONS, field.icon, field.iconColor);
        drawText(dc, field.numberX, field.numberY, field.numberFont, field.number,
            field.numberColor);
    }

    // The pill (its own well), then the icon if shown, the number and
    // "/ goal" if any.
    private function paintBottomField(dc as Dc, field as BottomFieldFrame) as Void {
        fillRoundedRect(dc, field.pill);
        if (field.icon.length() > 0) {
            drawText(dc, field.iconX, field.iconY, FONT_ICONS, field.icon, field.iconColor);
        }
        drawText(dc, field.numberX, field.numberY, field.numberFont, field.number,
            field.numberColor);
        if (field.goal.length() > 0) {
            drawText(dc, field.goalX, field.goalY, FONT_GOAL_15, field.goal, field.goalColor);
        }
    }

    // An Always On frame: no buffers, only the filled time, the date pill's
    // outline (the pill filled, its inside filled black again) and the date
    // text on black.
    function paintAod(dc as Dc, frame as AodFrame) as Void {
        clear(dc);
        drawText(dc, frame.timeX, frame.timeY, FONT_TIME, frame.time, frame.timeColor);
        fillRoundedRect(dc, frame.datePill);
        fillRoundedRect(dc, frame.datePillInner);
        drawText(dc, frame.dateX, frame.dateY, FONT_DATE, frame.date, frame.dateColor);
    }

    // ---- Buffers ----

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

    // The minute buffer, null if the graphics pool has no room for it.
    private function minuteBitmap(width as Number, height as Number) as BufferedBitmap? {
        var bitmap = _minuteBitmap;
        if (bitmap != null) {
            return bitmap;
        }
        try {
            var reference = _minuteReference;
            if (reference == null) {
                reference = Graphics.createBufferedBitmap({ :width => width, :height => height });
                _minuteReference = reference;
            }
            bitmap = reference.get() as BufferedBitmap?;
        } catch (e instanceof Graphics.OutOfGraphicsMemoryException) {
            return null;
        }
        _minuteBitmap = bitmap;
        return bitmap;
    }

    // Everything that depends only on the face config (its theme and field
    // mapping), back to front.
    private function paintStatic(dc as Dc, layer as StaticLayer) as Void {
        Timing.start(TIMING_STATIC);
        clear(dc);

        dc.setColor(layer.backgroundColor, layer.backgroundColor);
        dc.fillCircle(Layout.CENTER_X, Layout.CENTER_Y, Layout.DISC_RADIUS);
        drawArc(dc, layer.edgeMask);
        drawLines(dc, layer.bezelTicks);

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

    // ---- Primitives ----

    private function drawText(dc as Dc, x as Number, y as Number, font as FontId,
            text as String, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, _fonts.get(font), text, Graphics.TEXT_JUSTIFY_LEFT);
    }

    private function fillCircle(dc as Dc, circle as Circle) as Void {
        dc.setColor(circle.color, circle.color);
        dc.fillCircle(circle.x, circle.y, circle.radius);
    }

    // Lines in order, setting the pen and the color only when they change
    // (bezel ticks come in runs of the same pen, and once the goal is
    // reached all lit ticks share the accent).
    private function drawLines(dc as Dc, lines as Array<Line>) as Void {
        var pen = -1;
        var color = -1;
        for (var i = 0; i < lines.size(); i++) {
            var line = lines[i];
            if (line.pen != pen) {
                pen = line.pen;
                dc.setPenWidth(pen);
            }
            if (line.color != color) {
                color = line.color;
                dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            }
            dc.drawLine(line.x1, line.y1, line.x2, line.y2);
        }
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
