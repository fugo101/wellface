import Toybox.Lang;
import Toybox.Math;
import Toybox.Test;

// The contour texture (Q43, stories 40-46, 67-68): its color in the static
// layer, and the contour pieces generated at build time
// (tools/contourgen/generate.py, resources/contours/) checked against the
// static layer's wells, so a layout change without regenerating the table
// fails here.
(:test)
module ContourTest {
    // The texture is accent x 0.36: mint #335242 ("Final design: main
    // elements", Background), volt #4C5726 (the design's shade(C, 0.36)).
    (:test)
    function theStaticLayerCarriesTheTextureColor(logger as Test.Logger) as Boolean {
        Test.assertEqual(0x335242, FaceModel.staticLayer(TestConfigs.mintDefault()).contourColor);
        var config = FaceConfigs.defaultConfig();
        config.themeName = Themes.VOLT;
        Test.assertEqual(0x4C5726, FaceModel.staticLayer(FaceModel.resolve(config)).contourColor);
        return true;
    }

    // One piece decoded from the table: its line, pen and points ([x, y]).
    class Piece {
        public var line as Number;
        public var pen as Number;
        public var points as Array<[Number, Number]>;

        function initialize(line as Number, pen as Number, points as Array<[Number, Number]>) {
            self.line = line;
            self.pen = pen;
            self.points = points;
        }
    }

    // The generated table, decoded. Fails if it is not a run of headers
    // each followed by its points.
    function pieces() as Array<Piece> {
        var table = Contours.table();
        var out = [] as Array<Piece>;
        var i = 0;
        while (i < table.size()) {
            var header = table[i];
            Test.assertMessage(header < 0, "a piece must start with a header at " + i);
            header = -header;
            var count = header & Contours.BYTE_MASK;
            Test.assertMessage(count >= 2 && i + count < table.size(), "bad count at " + i);
            var points = [] as Array<[Number, Number]>;
            for (var k = 1; k <= count; k++) {
                var p = table[i + k];
                Test.assertMessage(p >= 0, "a point must not be negative at " + (i + k));
                points.add([p >> Contours.POINT_SHIFT, p & Contours.POINT_MASK]);
            }
            out.add(new Piece(header >> Contours.LINE_SHIFT,
                (header >> Contours.PEN_SHIFT) & Contours.BYTE_MASK, points));
            i += count + 1;
        }
        return out;
    }

    // Lines 1-30, the ones that reach the background disc, in order outward
    // from the peak; pen 2, every 5th line pen 3 (Q43).
    (:test)
    function everyLineThatReachesTheDiscIsThereInOrder(logger as Test.Logger) as Boolean {
        var all = pieces();
        var seen = new Array<Boolean>[31];
        var previous = 0;
        for (var i = 0; i < all.size(); i++) {
            var piece = all[i];
            Test.assertMessage(piece.line >= previous, "lines out of order at piece " + i);
            Test.assertMessage(piece.line >= 1 && piece.line <= 30, "line " + piece.line);
            Test.assertEqualMessage(piece.pen, piece.line % 5 == 0 ? 3 : 2, "pen of line " + piece.line);
            seen[piece.line] = true;
            previous = piece.line;
        }
        for (var l = 1; l <= 30; l++) {
            Test.assertMessage(seen[l] == true, "no piece of line " + l);
        }
        return true;
    }

    // Every segment of every piece stays at least half a pen inside the
    // background disc and at least a pen width outside every well: the time
    // band, the round fields and the bottom field measured at their rims,
    // and the battery well (an arc band with round caps, no rim). The wells
    // come from the static layer, so moving one without running
    // scripts/gen-contours.sh fails here.
    (:test)
    function everyPieceKeepsItsMargins(logger as Test.Logger) as Boolean {
        var layer = FaceModel.staticLayer(TestConfigs.mintDefault());
        var rects = [layer.timeBandRim, layer.bottomFieldRim] as Array<RoundedRect>;
        var circles = [] as Array<Circle>;
        circles.addAll(layer.fieldRims);
        circles.addAll(layer.batteryCaps);
        var battery = layer.batteryWell;
        var all = pieces();
        var segments = 0;
        for (var i = 0; i < all.size(); i++) {
            var piece = all[i];
            var pen = piece.pen.toFloat();
            var inside = Layout.DISC_RADIUS - pen / 2;
            var pts = piece.points;
            for (var k = 0; k < pts.size(); k++) {
                var r = distance(pts[k][0], pts[k][1], Layout.CENTER_X, Layout.CENTER_Y);
                Test.assertMessage(r <= inside,
                    "line " + piece.line + " point " + pts[k] + " is " + r + " from the center");
            }
            for (var k = 0; k + 1 < pts.size(); k++) {
                var a = [pts[k][0].toFloat(), pts[k][1].toFloat()] as [Float, Float];
                var b = [pts[k + 1][0].toFloat(), pts[k + 1][1].toFloat()] as [Float, Float];
                var where = "line " + piece.line + " segment " + pts[k] + "-" + pts[k + 1];
                for (var c = 0; c < circles.size(); c++) {
                    var circle = circles[c];
                    var d = segmentPointDistance(a, b, circle.x.toFloat(), circle.y.toFloat())
                        - circle.radius;
                    Test.assertMessage(d >= pen, where + " is " + d + " from a circle");
                }
                for (var c = 0; c < rects.size(); c++) {
                    var d = segmentRectDistance(a, b, rects[c]);
                    Test.assertMessage(d >= pen, where + " is " + d + " from a rounded rect");
                }
                var d = segmentArcDistance(a, b, battery);
                Test.assertMessage(d >= pen, where + " is " + d + " from the battery well");
                segments++;
            }
        }
        // Not empty: the design's 30 lines leave several hundred segments in
        // the gaps.
        Test.assertMessage(segments > 300, "only " + segments + " segments");
        return true;
    }

    // ---- Geometry (exact, no sampling) ----

    function distance(x1 as Numeric, y1 as Numeric, x2 as Numeric, y2 as Numeric) as Float {
        var dx = (x1 - x2).toFloat();
        var dy = (y1 - y2).toFloat();
        return Math.sqrt(dx * dx + dy * dy).toFloat();
    }

    // The distance from segment a-b to the point (px, py).
    function segmentPointDistance(a as [Float, Float], b as [Float, Float], px as Float,
            py as Float) as Float {
        var vx = b[0] - a[0];
        var vy = b[1] - a[1];
        var length2 = vx * vx + vy * vy;
        var t = 0.0;
        if (length2 > 0) {
            t = ((px - a[0]) * vx + (py - a[1]) * vy) / length2;
            t = t < 0 ? 0.0 : (t > 1 ? 1.0 : t);
        }
        return distance(a[0] + t * vx, a[1] + t * vy, px, py);
    }

    // Whether segments a-b and c-d cross.
    function crosses(a as [Float, Float], b as [Float, Float], c as [Float, Float],
            d as [Float, Float]) as Boolean {
        var d1 = cross(c, d, a);
        var d2 = cross(c, d, b);
        var d3 = cross(a, b, c);
        var d4 = cross(a, b, d);
        return ((d1 > 0) != (d2 > 0)) && ((d3 > 0) != (d4 > 0));
    }

    function cross(o as [Float, Float], p as [Float, Float], q as [Float, Float]) as Float {
        return (p[0] - o[0]) * (q[1] - o[1]) - (p[1] - o[1]) * (q[0] - o[0]);
    }

    // The distance from segment a-b to a rounded rect: to its inner rect
    // (inset by the radius; convex, so 0 if an end is inside or the segment
    // crosses an edge, else the least of the ends' distances to it and its
    // corners' distances to the segment), less the radius.
    function segmentRectDistance(a as [Float, Float], b as [Float, Float],
            rect as RoundedRect) as Float {
        var x0 = (rect.x + rect.radius).toFloat();
        var y0 = (rect.y + rect.radius).toFloat();
        var x1 = (rect.x + rect.width - rect.radius).toFloat();
        var y1 = (rect.y + rect.height - rect.radius).toFloat();
        var d = pointRectDistance(a, x0, y0, x1, y1);
        var db = pointRectDistance(b, x0, y0, x1, y1);
        d = db < d ? db : d;
        var corners = [[x0, y0], [x1, y0], [x1, y1], [x0, y1]] as Array<[Float, Float]>;
        for (var i = 0; i < 4 && d > 0; i++) {
            if (crosses(a, b, corners[i], corners[(i + 1) % 4])) {
                d = 0.0;
            }
        }
        for (var i = 0; i < 4 && d > 0; i++) {
            var dc = segmentPointDistance(a, b, corners[i][0], corners[i][1]);
            d = dc < d ? dc : d;
        }
        return d - rect.radius;
    }

    function pointRectDistance(p as [Float, Float], x0 as Float, y0 as Float, x1 as Float,
            y1 as Float) as Float {
        var dx = x0 - p[0] > p[0] - x1 ? x0 - p[0] : p[0] - x1;
        var dy = y0 - p[1] > p[1] - y1 ? y0 - p[1] : p[1] - y1;
        return distance(dx > 0 ? dx : 0.0, dy > 0 ? dy : 0.0, 0, 0);
    }

    // The distance from segment a-b to the band within pen / 2 of an arc in
    // the arc contract (its round caps are circles of their own, checked
    // with the other circles): 0 if the part of the segment inside the
    // arc's wedge crosses the arc's centerline, else | |p| - r | at its
    // nearest point, less pen / 2. Outside the wedge the arc's nearest
    // points are its ends, whose caps cover them.
    function segmentArcDistance(a as [Float, Float], b as [Float, Float], arc as Arc) as Float {
        var cx = arc.x.toFloat();
        var cy = arc.y.toFloat();
        // The wedge in math orientation (y up): from the end angle
        // counter-clockwise to the start angle (drawn clockwise from start
        // to end, sweep < 180).
        var start = Math.toRadians(arc.start);
        var end = Math.toRadians(arc.end);
        // Inside when cross(u_end, v) >= 0 and cross(v, u_start) >= 0, with
        // v = (px - cx, cy - py).
        var sides = [
            [-Math.sin(end), Math.cos(end)],
            [Math.sin(start), -Math.cos(start)]
        ] as Array<[Float, Float]>;
        var t0 = 0.0;
        var t1 = 1.0;
        for (var i = 0; i < 2; i++) {
            var fa = sides[i][0] * (a[0] - cx) + sides[i][1] * (cy - a[1]);
            var fb = sides[i][0] * (b[0] - cx) + sides[i][1] * (cy - b[1]);
            if (fa < 0 && fb < 0) {
                return 1000.0;
            }
            if (fa < 0 || fb < 0) {
                var t = fa / (fa - fb);
                if (fa < 0) {
                    t0 = t > t0 ? t : t0;
                } else {
                    t1 = t < t1 ? t : t1;
                }
            }
        }
        if (t0 > t1) {
            return 1000.0;
        }
        var p = [a[0] + t0 * (b[0] - a[0]), a[1] + t0 * (b[1] - a[1])] as [Float, Float];
        var q = [a[0] + t1 * (b[0] - a[0]), a[1] + t1 * (b[1] - a[1])] as [Float, Float];
        var near = segmentPointDistance(p, q, cx, cy);
        var farP = distance(p[0], p[1], cx, cy);
        var farQ = distance(q[0], q[1], cx, cy);
        var far = farP > farQ ? farP : farQ;
        var d = 0.0;
        if (far < arc.radius) {
            d = arc.radius - far;
        } else if (near > arc.radius) {
            d = near - arc.radius;
        }
        return d - arc.pen / 2.0;
    }
}
