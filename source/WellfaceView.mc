import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class WellfaceView extends WatchUi.WatchFace {
    private var _theme as Theme;
    private var _mapping as FieldMapping;
    private var _reader as DataReader;
    private var _renderer as Renderer;
    // The last computed frames, one per mode. FaceModel runs again only
    // when the reader reports a change, which drops both.
    private var _frame as Frame?;
    private var _aodFrame as AodFrame?;

    function initialize() {
        WatchFace.initialize();
        _theme = Themes.active();
        _mapping = Layout.defaultMapping();
        _reader = new DataReader();
        _renderer = new Renderer(FaceModel.staticLayer(_theme, _mapping),
            FaceModel.bezelNotches(_theme), new Fonts());
    }

    function onUpdate(dc as Dc) as Void {
        var mode = System.getDisplayMode();
        if (mode == System.DISPLAY_MODE_OFF) {
            _reader.screenOff();
            return;
        }
        var highPower = mode == System.DISPLAY_MODE_HIGH_POWER;
        if (_reader.update(highPower)) {
            _frame = null;
            _aodFrame = null;
        }
        dc.setAntiAlias(true);

        if (!highPower) {
            // Always On: only the clock was read, no sensors.
            var aodFrame = _aodFrame;
            if (aodFrame == null) {
                aodFrame = FaceModel.computeAod(_reader.snapshot(), _theme);
                _aodFrame = aodFrame;
            }
            _renderer.paintAod(dc, aodFrame);
            return;
        }

        var frame = _frame;
        if (frame == null) {
            frame = FaceModel.compute(_reader.snapshot(), _theme, _mapping);
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
