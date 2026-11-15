import Toybox.Lang;
import Toybox.WatchUi;

// The contour texture's pieces (Q43): short runs of the design's contour
// lines, cut at build time (tools/contourgen/generate.py, scripts/
// gen-contours.sh) so they lie inside the background disc and clear of every
// well. They are fixed, so they live in a resource, loaded only while the
// static layer is painted, as packed numbers rather than one object per
// piece.
//
// The table is a run of pieces, line by line outward from the peak (lines
// 1-30). Each piece is a header, -(line << LINE_SHIFT | pen << PEN_SHIFT |
// count), then `count` points, each x << POINT_SHIFT | y in whole pixels,
// joined by straight lines. Headers are negative, points are not.
module Contours {
    const LINE_SHIFT = 16;
    const PEN_SHIFT = 8;
    const BYTE_MASK = 0xFF;
    const POINT_SHIFT = 9;
    const POINT_MASK = 0x1FF;

    // The packed pieces.
    function table() as Array<Number> {
        return WatchUi.loadResource(Rez.JsonData.Contours) as Array<Number>;
    }
}
