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
    // Between onEnterSleep and onExitSleep: no per-second updates.
    private var _asleep as Boolean = false;

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
    // resolves it, hands the renderer the static layer built for it (the
    // buffer is repainted once), drops both cached frames (a config change
    // counts as every change kind) and gives the reader the config's read
    // plan, which makes its next high-power update count as a wake, so
    // every metric it shows (and the zones, if needed) is read before the
    // next frame. Returns the resolved config for the caller to
    // keep in _config.
    private function apply(config as FaceConfig) as ResolvedFaceConfig {
        var resolved = FaceModel.resolve(config);
        _renderer.setStatic(FaceModel.staticLayer(resolved), FaceModel.everySecondParts(resolved),
            FaceModel.everyMinuteParts(resolved));
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
        // On the FR265 the face sleeps (onEnterSleep) about 10 s after a
        // wake even while a tap keeps the screen lit in high power: it then
        // gets an update once a minute, so it shows no seconds rather than
        // frozen ones (Q41).
        var timing = !highPower ? TIMING_AOD : _asleep ? TIMING_ASLEEP : TIMING_UPDATE;
        Timing.start(timing);
        var changes = _reader.update(highPower, !_asleep);
        _frameChanges |= changes;
        // The Always On frame has no seconds, so a second change alone never
        // makes it stale (AOD does no work for the seconds, Q41).
        _aodChanges |= changes & ~CHANGE_SECOND;
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
            Timing.stop(timing);
            return;
        }

        var frame = _frame;
        // Whether the minute content must be rebuilt (a new frame comes with
        // a new static layer, which already marks it).
        var minuteChanged = false;
        if (frame == null || _frameChanges != 0) {
            minuteChanged = FaceModel.minuteLayerChanged(_frameChanges, _config);
            var snapshot = _reader.snapshot();
            // A change of the second alone is FaceModel.update's fast path
            // (the seconds' text only). It is not timed as a frame, so the
            // timing log still splits updates into those that recomputed
            // data and those that did not, as in the baseline.
            var timed = frame == null || _frameChanges != CHANGE_SECOND;
            if (timed) {
                Timing.start(TIMING_FRAME);
            }
            frame = FaceModel.update(frame, snapshot, _config, _frameChanges);
            if (timed) {
                Timing.stop(TIMING_FRAME);
            }
            _frame = frame;
            _frameChanges = 0;
        }
        if (_asleep) {
            // No per-second updates follow, so the minute layer is not
            // rebuilt for this frame.
            _renderer.showAtOnce();
        }
        _renderer.paint(dc, frame, minuteChanged);
        Timing.stop(timing);
    }

    // These set the sleep state read in onUpdate and ask for a repaint. The
    // timing build prints its readings here, outside any timed update.
    function onEnterSleep() as Void {
        _asleep = true;
        Timing.flush("sleep");
        WatchUi.requestUpdate();
    }

    function onExitSleep() as Void {
        _asleep = false;
        _renderer.showAtOnce();
        WatchUi.requestUpdate();
    }

    // Back from the widget loop, in high power with per-second updates
    // (WatchFace docs: "when returning from another app"); the buffers were
    // kept (Renderer).
    function onShow() as Void {
        _asleep = false;
        _renderer.showAtOnce();
    }

    // Going to the widgets leaves the face without onEnterSleep: the widget
    // loop hides the view, a widget opened in full stops the app.
    function onHide() as Void {
        Timing.flush("hide");
    }
}
