import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// Owns the applied face config: the delegate reads it from here, and
// applyConfig is the only place that changes it.
class WellfaceView extends WatchUi.WatchFace {
    private var _config as ResolvedFaceConfig;
    private var _reader as DataReader;
    private var _renderer as Renderer;
    // The last computed frames, one per mode. FaceModel runs again only
    // when the reader reports a change or a face config is applied, which
    // drop both.
    private var _frame as Frame?;
    private var _aodFrame as AodFrame?;

    function initialize() {
        WatchFace.initialize();
        _reader = new DataReader();
        _renderer = new Renderer(new Fonts());
        // Startup applies the built-in face config through the same path.
        _config = apply(FaceConfigs.defaultConfig());
    }

    // The applied face config, already resolved.
    function config() as ResolvedFaceConfig {
        return _config;
    }

    // Applies a face config (settings will call this).
    function applyConfig(config as FaceConfig) as Void {
        _config = apply(config);
    }

    // The apply-config path, the only place a face config takes effect:
    // resolves it, hands the renderer the static layer and bezel notches
    // built for it (the buffer is repainted once), drops both cached frames
    // and makes the next high-power update count as a wake, so every metric
    // it shows is read before the next frame. Returns the resolved config
    // for the caller to keep in _config.
    private function apply(config as FaceConfig) as ResolvedFaceConfig {
        var resolved = FaceModel.resolve(config);
        _renderer.setStatic(FaceModel.staticLayer(resolved), FaceModel.bezelNotches(resolved));
        _frame = null;
        _aodFrame = null;
        _reader.countNextUpdateAsWake();
        return resolved;
    }

    function onUpdate(dc as Dc) as Void {
        var mode = System.getDisplayMode();
        if (mode == System.DISPLAY_MODE_OFF) {
            _reader.countNextUpdateAsWake();
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
                aodFrame = FaceModel.computeAod(_reader.snapshot(), _config);
                _aodFrame = aodFrame;
            }
            _renderer.paintAod(dc, aodFrame);
            return;
        }

        var frame = _frame;
        if (frame == null) {
            frame = FaceModel.compute(_reader.snapshot(), _config);
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
