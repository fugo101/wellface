import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// The generated bitmap fonts, loaded once when the view starts.
class Fonts {
    public var time as FontResource;

    function initialize() {
        time = WatchUi.loadResource(Rez.Fonts.TimeFilled) as FontResource;
    }
}
