import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class WellfaceApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    // The timing build prints its last readings.
    function onStop(state as Dictionary?) as Void {
        Timing.flush("stop");
    }

    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        // The delegate reads the face config the view owns.
        var view = new WellfaceView();
        return [view, new WellfaceDelegate(view)];
    }
}
