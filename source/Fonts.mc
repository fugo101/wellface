import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// The generated bitmap fonts, loaded once when the view starts.
class Fonts {
    public var time as FontResource;
    public var date as FontResource;
    public var number48 as FontResource;
    public var number26 as FontResource;
    public var number22 as FontResource;
    public var number18 as FontResource;
    public var icons as FontResource;

    function initialize() {
        time = WatchUi.loadResource(Rez.Fonts.TimeFilled) as FontResource;
        date = WatchUi.loadResource(Rez.Fonts.Date) as FontResource;
        number48 = WatchUi.loadResource(Rez.Fonts.Number48) as FontResource;
        number26 = WatchUi.loadResource(Rez.Fonts.Number26) as FontResource;
        number22 = WatchUi.loadResource(Rez.Fonts.Number22) as FontResource;
        number18 = WatchUi.loadResource(Rez.Fonts.Number18) as FontResource;
        icons = WatchUi.loadResource(Rez.Fonts.Icons) as FontResource;
    }

    // The loaded font for a FaceModel number font.
    function number(font as NumberFont) as FontResource {
        switch (font) {
            case NUMBER_FONT_26:
                return number26;
            case NUMBER_FONT_22:
                return number22;
            case NUMBER_FONT_18:
                return number18;
        }
        return number48;
    }
}
