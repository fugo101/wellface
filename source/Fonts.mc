import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Every font in the font catalog, loaded once when the view starts. The
// renderer draws a FaceModel font id with the font loaded from the same
// catalog entry that FaceModel measured it with.
class Fonts {
    // Indexed by FontId.
    private var _loaded as Array<FontResource>;

    function initialize() {
        var entries = FontCatalog.entries();
        _loaded = new Array<FontResource>[entries.size()];
        for (var i = 0; i < entries.size(); i++) {
            _loaded[i] = WatchUi.loadResource(entries[i].resource) as FontResource;
        }
    }

    function get(id as FontId) as FontResource {
        return _loaded[id as Number];
    }
}
