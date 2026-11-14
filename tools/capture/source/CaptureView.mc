import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Paints one fixed scenario (CaptureScenario.NAME) through the face's own
// FaceModel and Renderer, whatever the display mode: "aod" paints the Always
// On frame, every other scenario the high-power frame. Keep the scenarios in
// step with the face's entry points when they change.
class CaptureView extends WatchUi.WatchFace {
    private var _theme as Theme;
    private var _mapping as FieldMapping;
    private var _renderer as Renderer;

    function initialize() {
        WatchFace.initialize();
        _theme = Themes.active();
        _mapping = Layout.defaultMapping();
        _renderer = new Renderer(FaceModel.staticLayer(_theme, _mapping),
            FaceModel.bezelNotches(_theme), new Fonts());
    }

    function onUpdate(dc as Dc) as Void {
        dc.setAntiAlias(true);
        var name = CaptureScenario.NAME;
        if (name.equals("aod")) {
            _renderer.paintAod(dc, FaceModel.computeAod(normal(), _theme));
            return;
        }
        _renderer.paint(dc, FaceModel.compute(snapshot(name), _theme, _mapping));
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
