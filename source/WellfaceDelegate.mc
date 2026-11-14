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
        // The default mapping until a face config owns it (ticket 03).
        var target = FaceModel.longPressTarget(point[0], point[1], Layout.defaultMapping());
        if (target == null) {
            return false;
        }
        try {
            Complications.exitTo(new Complications.Id(Metrics.entry(target.metric).complication));
        } catch (e instanceof Lang.Exception) {
            return false;
        }
        return true;
    }
}
