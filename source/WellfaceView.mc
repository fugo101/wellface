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
    // The last computed frames, one per mode, and for each the change kinds
    // (ChangeKind bits) the reader reported since it was last computed. A
    // frame is updated only for those (FaceModel.update), so a clock change
    // seen in AOD reaches the high-power frame on the next wake. Applying a
    // face config drops both frames.
    private var _frame as Frame?;
    private var _aodFrame as AodFrame?;
    private var _frameChanges as Number = 0;
    private var _aodChanges as Number = 0;

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
    // (a config change counts as every change kind) and gives the reader the
    // config's read plan, which makes its next high-power update count as a
    // wake, so every metric it shows (and the zones, if needed) is read
    // before the next frame. Returns the resolved config for the caller to
    // keep in _config.
    private function apply(config as FaceConfig) as ResolvedFaceConfig {
        var resolved = FaceModel.resolve(config);
        _renderer.setStatic(FaceModel.staticLayer(resolved), FaceModel.bezelNotches(resolved));
        _frame = null;
        _aodFrame = null;
        _frameChanges = CHANGE_ALL;
        _aodChanges = CHANGE_ALL;
        _reader.setReadPlan(FaceModel.readPlan(resolved));
        return resolved;
    }

    function onUpdate(dc as Dc) as Void {
        var mode = System.getDisplayMode();
        if (mode == System.DISPLAY_MODE_OFF) {
            _reader.countNextUpdateAsWake();
            return;
        }
        var highPower = mode == System.DISPLAY_MODE_HIGH_POWER;
        Timing.start(highPower ? TIMING_UPDATE : TIMING_AOD);
        var changes = _reader.update(highPower);
        _frameChanges |= changes;
        _aodChanges |= changes;
        dc.setAntiAlias(true);

        if (!highPower) {
            // Always On: only the clock was read, no sensors. Kept unless the
            // clock changed.
            var aodFrame = _aodFrame;
            if (aodFrame == null || _aodChanges != 0) {
                var aodSnapshot = _reader.snapshot();
                Timing.start(TIMING_AOD_FRAME);
                aodFrame = FaceModel.updateAod(aodFrame, aodSnapshot, _config, _aodChanges);
                Timing.stop(TIMING_AOD_FRAME);
                _aodFrame = aodFrame;
                _aodChanges = 0;
            }
            _renderer.paintAod(dc, aodFrame);
            Timing.stop(TIMING_AOD);
            return;
        }

        var frame = _frame;
        if (frame == null || _frameChanges != 0) {
            var snapshot = _reader.snapshot();
            Timing.start(TIMING_FRAME);
            frame = FaceModel.update(frame, snapshot, _config, _frameChanges);
            Timing.stop(TIMING_FRAME);
            _frame = frame;
            _frameChanges = 0;
        }
        _renderer.paint(dc, frame);
        Timing.stop(TIMING_UPDATE);
    }

    // The mode is read in onUpdate; these only ask for a repaint. The timing
    // build prints its readings here, outside any timed update.
    function onEnterSleep() as Void {
        Timing.flush("sleep");
        WatchUi.requestUpdate();
    }

    function onExitSleep() as Void {
        WatchUi.requestUpdate();
    }

    // A return to the widgets leaves the face without onEnterSleep.
    function onHide() as Void {
        Timing.flush("hide");
    }
}
