import Toybox.Complications;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// Opens the Garmin page for a held field. Thin and untested; FaceModel
// decides what a touch point hits.
class WellfaceDelegate extends WatchUi.WatchFaceDelegate {
    function initialize() {
        WatchFaceDelegate.initialize();
    }

    // A touch and hold. Only in high power: in AOD the fields are not shown,
    // so a hold there does nothing. Returns false, so the system handles the
    // hold, on a miss or when the page cannot be opened.
    function onPress(clickEvent as WatchUi.ClickEvent) as Boolean {
        if (System.getDisplayMode() != System.DISPLAY_MODE_HIGH_POWER) {
            return false;
        }
        var point = clickEvent.getCoordinates();
        var target = FaceModel.longPressTarget(point[0], point[1]);
        if (target == null) {
            return false;
        }
        try {
            Complications.exitTo(new Complications.Id(complicationType(target.metric)));
        } catch (e instanceof Lang.Exception) {
            return false;
        }
        return true;
    }

    // The native complication whose Garmin page shows a metric.
    private function complicationType(metric as Metric) as Complications.Type {
        switch (metric) {
            case METRIC_STRESS:
                return Complications.COMPLICATION_TYPE_STRESS;
            case METRIC_BODY_BATTERY:
                return Complications.COMPLICATION_TYPE_BODY_BATTERY;
            case METRIC_HEART_RATE:
                return Complications.COMPLICATION_TYPE_HEART_RATE;
            case METRIC_STEPS:
                return Complications.COMPLICATION_TYPE_STEPS;
        }
        // Unreachable: every metric is listed above.
        return Complications.COMPLICATION_TYPE_STEPS;
    }
}
