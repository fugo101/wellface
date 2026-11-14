import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class WellfaceApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        // The delegate reads the face config the view owns.
        var view = new WellfaceView();
        return [view, new WellfaceDelegate(view)];
    }
}
