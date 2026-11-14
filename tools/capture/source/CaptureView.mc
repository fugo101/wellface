import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Paints one fixed scenario (CaptureScenario.NAME) through the face's own
// FaceModel and Renderer, whatever the display mode: "aod" paints the Always
// On frame, every other scenario the high-power frame. Keep the scenarios in
// step with the face's entry points when they change.
class CaptureView extends WatchUi.WatchFace {
    private var _config as ResolvedFaceConfig;
    private var _renderer as Renderer;

    // The built-in face config with the scenario's theme
    // (CaptureScenario.THEME), set up as WellfaceView.applyConfig does.
    function initialize() {
        WatchFace.initialize();
        var config = FaceConfigs.defaultConfig();
        config.themeName = CaptureScenario.THEME;
        _config = FaceModel.resolve(config);
        _renderer = new Renderer(new Fonts());
        _renderer.setStatic(FaceModel.staticLayer(_config), FaceModel.bezelNotches(_config));
    }

    function onUpdate(dc as Dc) as Void {
        dc.setAntiAlias(true);
        var name = CaptureScenario.NAME;
        if (name.equals("aod")) {
            _renderer.paintAod(dc, FaceModel.computeAod(normal(), _config));
            return;
        }
        _renderer.paint(dc, FaceModel.compute(snapshot(name), _config));
    }

    // Thursday 12/11, 08:42, every value known, heart rate in zone 2.
    private function normal() as Snapshot {
        var s = new Snapshot(8, 42);
        s.weekdayName = "Thu";
        s.weekdayNumber = 5;
        s.day = 12;
        s.month = 11;
        s.battery = 64;
        s.setValue(METRIC_STEPS, 1147);
        s.setGoal(METRIC_STEPS, 3110);
        s.setValue(METRIC_BODY_BATTERY, 56);
        s.setValue(METRIC_STRESS, 27);
        s.setValue(METRIC_HEART_RATE, 128);
        s.heartRateZones = [96, 115, 134, 154, 173, 192] as Array<Number>;
        return s;
    }

    private function snapshot(name as String) as Snapshot {
        if (name.equals("missing")) {
            return new Snapshot(8, 42);
        }
        var s = normal();
        if (name.equals("goalReached")) {
            s.setValue(METRIC_STEPS, 3110);
        } else if (name.equals("longSteps")) {
            s.setValue(METRIC_STEPS, 12345);
            s.setGoal(METRIC_STEPS, 15000);
        } else if (name.equals("steps100000")) {
            s.setValue(METRIC_STEPS, 100000);
        } else if (name.equals("warning")) {
            // Level 2 everywhere, and heart rate in zone 5.
            s.battery = 5;
            s.setValue(METRIC_BODY_BATTERY, 10);
            s.setValue(METRIC_STRESS, 80);
            s.setValue(METRIC_HEART_RATE, 180);
        }
        return s;
    }
}
