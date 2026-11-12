import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class WellfaceView extends WatchUi.WatchFace {
    private var _theme as Theme;
    private var _fonts as Fonts;
    // The last computed frame and the minute it was computed for.
    private var _frame as Frame?;
    private var _hour as Number = -1;
    private var _minute as Number = -1;

    function initialize() {
        WatchFace.initialize();
        _theme = Themes.active();
        _fonts = new Fonts();
    }

    function onUpdate(dc as Dc) as Void {
        var mode = System.getDisplayMode();
        if (mode == System.DISPLAY_MODE_OFF) {
            return;
        }
        dc.setAntiAlias(true);

        if (mode != System.DISPLAY_MODE_HIGH_POWER) {
            // Always On: black until ticket 11 adds the AOD frame, so an
            // intermediate build never shows the full face in low power.
            Renderer.clear(dc);
            return;
        }

        var clock = System.getClockTime();
        var frame = _frame;
        if (frame == null || clock.hour != _hour || clock.min != _minute) {
            frame = FaceModel.compute(new Snapshot(clock.hour, clock.min), _theme);
            _frame = frame;
            _hour = clock.hour;
            _minute = clock.min;
        }
        Renderer.paint(dc, frame, _fonts);
    }

    // The mode is read in onUpdate; these only ask for a repaint.
    function onEnterSleep() as Void {
        WatchUi.requestUpdate();
    }

    function onExitSleep() as Void {
        WatchUi.requestUpdate();
    }
}
