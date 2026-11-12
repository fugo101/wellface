import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// The generated bitmap fonts, loaded once when the view starts.
class Fonts {
    public var time as FontResource;
    public var date as FontResource;
    public var number48 as FontResource;
    public var icons as FontResource;

    function initialize() {
        time = WatchUi.loadResource(Rez.Fonts.TimeFilled) as FontResource;
        date = WatchUi.loadResource(Rez.Fonts.Date) as FontResource;
        number48 = WatchUi.loadResource(Rez.Fonts.Number48) as FontResource;
        icons = WatchUi.loadResource(Rez.Fonts.Icons) as FontResource;
    }

    // The loaded font for a FaceModel number font.
    function number(font as NumberFont) as FontResource {
        return number48;
    }
}
