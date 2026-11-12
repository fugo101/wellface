import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class WellfaceView extends WatchUi.WatchFace {
    private var _theme as Theme;
    private var _reader as DataReader;
    private var _renderer as Renderer;
    // The last computed frame; FaceModel runs again only when the reader
    // reports a change.
    private var _frame as Frame?;

    function initialize() {
        WatchFace.initialize();
        _theme = Themes.active();
        _reader = new DataReader();
        _renderer = new Renderer(FaceModel.staticLayer(_theme), FaceModel.bezelNotches(_theme),
            new Fonts());
    }

    function onUpdate(dc as Dc) as Void {
        var mode = System.getDisplayMode();
        if (mode == System.DISPLAY_MODE_OFF) {
            _reader.screenOff();
            return;
        }
        var highPower = mode == System.DISPLAY_MODE_HIGH_POWER;
        var changed = _reader.update(highPower);
        dc.setAntiAlias(true);

        if (!highPower) {
            // Always On: black until ticket 11 adds the AOD frame, so an
            // intermediate build never shows the full face in low power.
            _renderer.clear(dc);
            return;
        }

        var frame = _frame;
        if (frame == null || changed) {
            frame = FaceModel.compute(_reader.snapshot(), _theme);
            _frame = frame;
        }
        _renderer.paint(dc, frame);
    }

    // The mode is read in onUpdate; these only ask for a repaint.
    function onEnterSleep() as Void {
        WatchUi.requestUpdate();
    }

    function onExitSleep() as Void {
        WatchUi.requestUpdate();
    }
}
