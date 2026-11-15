import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Paints one fixed scenario (CaptureScenario.NAME) through the face's own
// FaceModel and Renderer, whatever the display mode: "frame12" paints the
// Always On frame (the design's frame 12, from frame 1's data), every other
// scenario the high-power frame. Keep the scenarios in step with the face's
// entry points when they change.
class CaptureView extends WatchUi.WatchFace {
    private var _config as ResolvedFaceConfig;
    private var _renderer as Renderer;
    // The frame painted last and the step of the per-second sequence.
    private var _frame as Frame? = null;
    private var _step as Number = 0;
    // Repaints spent waiting for the minute layer, at most MAX_SETTLING.
    private var _settling as Number = 0;
    const MAX_SETTLING = 5;

    // The built-in face config with the scenario's theme
    // (CaptureScenario.THEME), set up as WellfaceView.applyConfig does.
    function initialize() {
        WatchFace.initialize();
        var config = FaceConfigs.defaultConfig();
        config.themeName = CaptureScenario.THEME;
        _config = FaceModel.resolve(config);
        _renderer = new Renderer(new Fonts());
        _renderer.forceFullRepaint = CaptureScenario.FULL_REPAINT;
        _renderer.setStatic(FaceModel.staticLayer(_config), FaceModel.everySecondParts(_config),
            FaceModel.everyMinuteParts(_config));
    }

    function onUpdate(dc as Dc) as Void {
        dc.setAntiAlias(true);
        var name = CaptureScenario.NAME;
        if (name.equals("frame12")) {
            _renderer.paintAod(dc, FaceModel.computeAod(frame1(), _config));
            return;
        }
        // The per-second path, through the same renderer calls as the face:
        // a frame with the second and heart rate before the scenario's,
        // repainted until the renderer has built its minute layer from it
        // (the first frames are drawn straight on the screen); then a
        // seconds-only update and a heart-rate-only update to the
        // scenario's data. Later updates repaint that frame. With
        // FULL_REPAINT every one of them is a full repaint.
        var frame = _frame;
        var target = snapshot(name);
        if (frame == null) {
            var before = snapshot(name);
            before.second = ((target.second as Number) + 59) % 60;
            before.setValue(METRIC_HEART_RATE, otherHeartRate(target));
            frame = FaceModel.compute(before, _config);
            _renderer.paint(dc, frame, true);
        } else if (_step == 1) {
            _renderer.paint(dc, frame, false);
            if (!_renderer.minuteLayerReady() && !CaptureScenario.FULL_REPAINT) {
                // Stay on this step until the minute layer is built; never
                // capture a full repaint as the per-second path.
                if (_settling >= MAX_SETTLING) {
                    throw new Lang.InvalidValueException("no minute layer after "
                        + MAX_SETTLING + " repaints");
                }
                _settling++;
                WatchUi.requestUpdate();
                return;
            }
        } else if (_step == 2) {
            var secondOnly = snapshot(name);
            secondOnly.setValue(METRIC_HEART_RATE, otherHeartRate(target));
            frame = FaceModel.update(frame, secondOnly, _config, CHANGE_SECOND);
            _renderer.paint(dc, frame, FaceModel.minuteLayerChanged(CHANGE_SECOND, _config));
        } else if (_step == 3) {
            frame = FaceModel.update(frame, target, _config, CHANGE_PER_SECOND);
            _renderer.paint(dc, frame, FaceModel.minuteLayerChanged(CHANGE_PER_SECOND, _config));
        } else {
            _renderer.paint(dc, frame, false);
        }
        _frame = frame;
        if (_step < 4) {
            _step++;
            WatchUi.requestUpdate();
        }
    }

    // A heart rate other than the scenario's, in another zone, so the
    // heart-rate-only update changes the field's number and segments.
    private function otherHeartRate(s as Snapshot) as Number {
        var heartRate = s.value(METRIC_HEART_RATE);
        return heartRate != null && heartRate >= 140 ? 70 : 150;
    }

    // The design's frame 1 (its 2026-11-14 update, NORMAL in its source):
    // Thursday 12/11 in Vietnamese (T5), 08:42:37, stress 27, Body Battery
    // 56, heart rate 62 (zone 0), 1.147 of 3.110 steps, battery 78%, and the
    // design's heart-rate zones (HRZ, plus a maximum).
    private function frame1() as Snapshot {
        var s = new Snapshot(8, 42);
        s.second = 37;
        s.weekdayName = fromCodePoints([0x54, 0x68, 0x1EE9, 0x20, 0x35] as Array<Number>);
        s.weekdayNumber = 5;
        s.day = 12;
        s.month = 11;
        s.battery = 78;
        s.setValue(METRIC_STEPS, 1147);
        s.setGoal(METRIC_STEPS, 3110);
        s.setValue(METRIC_BODY_BATTERY, 56);
        s.setValue(METRIC_STRESS, 27);
        s.setValue(METRIC_HEART_RATE, 62);
        s.heartRateZones = [95, 114, 133, 152, 171, 190] as Array<Number>;
        return s;
    }

    // A string spelled out code point by code point, so the source stays
    // ASCII (as FaceModelTest and GoldenTest do).
    private function fromCodePoints(codePoints as Array<Number>) as String {
        var text = "";
        for (var i = 0; i < codePoints.size(); i++) {
            text += codePoints[i].toChar();
        }
        return text;
    }

    // Each scenario is a design frame (its number in the design's frame
    // list) with the frame's data, on top of frame 1, or one of four cases
    // the design has no frame for. Elements not built yet show today's look.
    private function snapshot(name as String) as Snapshot {
        var s = frame1();
        if (name.equals("frame1sec00")) {
            // The widest seconds.
            s.second = 0;
        } else if (name.equals("frame2")) {
            // Level 1 warnings.
            s.setValue(METRIC_BODY_BATTERY, 22);
            s.setValue(METRIC_STRESS, 68);
            s.battery = 18;
        } else if (name.equals("frame3")) {
            // Level 2 warnings.
            s.setValue(METRIC_BODY_BATTERY, 12);
            s.setValue(METRIC_STRESS, 82);
            s.battery = 9;
        } else if (name.equals("frame5")) {
            // Active: heart rate 142, zone 3.
            s.hour = 17;
            s.minute = 30;
            s.setValue(METRIC_BODY_BATTERY, 41);
            s.setValue(METRIC_STRESS, 74);
            s.setValue(METRIC_HEART_RATE, 142);
            s.setValue(METRIC_STEPS, 2480);
            s.battery = 52;
        } else if (name.equals("frame7")) {
            // Step goal reached.
            s.hour = 19;
            s.minute = 5;
            s.setValue(METRIC_STEPS, 3512);
            s.setValue(METRIC_BODY_BATTERY, 33);
        } else if (name.equals("frame11")) {
            // Missing data; the clock, the date and the goal stay.
            s.setValue(METRIC_STRESS, null);
            s.setValue(METRIC_HEART_RATE, null);
            s.setValue(METRIC_BODY_BATTERY, null);
            s.setValue(METRIC_STEPS, null);
            s.battery = null;
        } else if (name.equals("frame11b")) {
            // Steps too long for the icon: 1.147 / 10.000.
            s.setGoal(METRIC_STEPS, 10000);
        } else if (name.equals("goalReached")) {
            // Exactly the goal.
            s.setValue(METRIC_STEPS, 3110);
        } else if (name.equals("warning")) {
            // Level 2 everywhere, battery 5%, and heart rate in zone 5.
            s.battery = 5;
            s.setValue(METRIC_BODY_BATTERY, 10);
            s.setValue(METRIC_STRESS, 80);
            s.setValue(METRIC_HEART_RATE, 180);
        } else if (name.equals("longSteps")) {
            s.setValue(METRIC_STEPS, 12345);
            s.setGoal(METRIC_STEPS, 15000);
        } else if (name.equals("steps100000")) {
            s.setValue(METRIC_STEPS, 100000);
        }
        return s;
    }
}
