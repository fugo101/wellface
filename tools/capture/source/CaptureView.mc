import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Paints one fixed scenario (CaptureScenario.NAME) through the face's own
// FaceModel and Renderer, whatever the display mode: "aod" paints the Always
// On frame, every other scenario the high-power frame. Keep the scenarios in
// step with the face's entry points when they change.
class CaptureView extends WatchUi.WatchFace {
    private var _theme as Theme;
    private var _renderer as Renderer;

    function initialize() {
        WatchFace.initialize();
        _theme = Themes.active();
        _renderer = new Renderer(FaceModel.staticLayer(_theme), FaceModel.bezelNotches(_theme),
            new Fonts());
    }

    function onUpdate(dc as Dc) as Void {
        dc.setAntiAlias(true);
        var name = CaptureScenario.NAME;
        if (name.equals("aod")) {
            _renderer.paintAod(dc, FaceModel.computeAod(normal(), _theme));
            return;
        }
        _renderer.paint(dc, FaceModel.compute(snapshot(name), _theme));
    }

    // Thursday 12/11, 08:42, every value known, heart rate in zone 2.
    private function normal() as Snapshot {
        var s = new Snapshot(8, 42);
        s.weekdayName = "Thu";
        s.weekdayNumber = 5;
        s.day = 12;
        s.month = 11;
        s.battery = 64;
        s.steps = 1147;
        s.stepGoal = 3110;
        s.bodyBattery = 56;
        s.stress = 27;
        s.heartRate = 128;
        s.heartRateZones = [96, 115, 134, 154, 173, 192] as Array<Number>;
        return s;
    }

    private function snapshot(name as String) as Snapshot {
        if (name.equals("missing")) {
            return new Snapshot(8, 42);
        }
        var s = normal();
        if (name.equals("goalReached")) {
            s.steps = 3110;
        } else if (name.equals("longSteps")) {
            s.steps = 12345;
            s.stepGoal = 15000;
        } else if (name.equals("steps100000")) {
            s.steps = 100000;
        } else if (name.equals("warning")) {
            // Level 2 everywhere, and heart rate in zone 5.
            s.battery = 5;
            s.bodyBattery = 10;
            s.stress = 80;
            s.heartRate = 180;
        }
        return s;
    }
}
