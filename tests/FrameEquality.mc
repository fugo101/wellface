import Toybox.Lang;

// Test-only equality for everything FaceModel outputs. Each value is
// described as text holding every member, and two values are equal when
// their descriptions are. The golden tests (GoldenTest) compare against
// recorded descriptions; GoldenTest's completeness tests change each member
// in turn and fail if the description does not change, so a member left out
// here fails a test.
//
// Names in the descriptions describe what is drawn, not today's member
// names, so the recorded golden values survive renames. Colors are six hex
// digits, icons their code points, fonts their resource names.
(:test)
module FrameEquality {
    function framesEqual(a as Frame, b as Frame) as Boolean {
        return describeFrame(a).equals(describeFrame(b));
    }

    function aodFramesEqual(a as AodFrame, b as AodFrame) as Boolean {
        return describeAod(a).equals(describeAod(b));
    }

    function layersEqual(a as StaticLayer, b as StaticLayer) as Boolean {
        return describeLayer(a).equals(describeLayer(b));
    }

    function targetsEqual(a as LongPressTarget?, b as LongPressTarget?) as Boolean {
        return describeTarget(a).equals(describeTarget(b));
    }

    function describeFrame(f as Frame) as String {
        return "time=" + f.time
            + "|timeWidth=" + f.timeWidth
            + "|timeX=" + f.timeX
            + "|timeY=" + f.timeY
            + "|timeColor=" + color(f.timeColor)
            + "|seconds=" + f.seconds
            + "|secondsX=" + f.secondsX
            + "|secondsY=" + f.secondsY
            + "|secondsColor=" + color(f.secondsColor)
            + "|date=" + f.date
            + "|dateWidth=" + f.dateWidth
            + "|dateX=" + f.dateX
            + "|dateY=" + f.dateY
            + "|weekday=" + f.weekday
            + "|weekdayColor=" + color(f.weekdayColor)
            + "|dayMonth=" + f.dayMonth
            + "|dayMonthX=" + f.dayMonthX
            + "|dayMonthColor=" + color(f.dayMonthColor)
            + "|datePill=" + rect(f.datePill)
            + "|batteryLit=" + arcs(f.batteryLit)
            + "|bezelLit=" + describeLines(f.bezelLit)
            + "|bezelLead=" + optionalLine(f.bezelLead)
            + "|goalReached=" + flag(f.bottomGoalReached)
            + "|bottom={" + describeBottomField(f.bottomField) + "}"
            + "|left={" + describeField(f.leftField) + "}"
            + "|center={" + describeField(f.centerField) + "}"
            + "|right={" + describeField(f.rightField) + "}";
    }

    function describeField(f as FieldFrame) as String {
        return "arcs=" + arcs(f.arcs)
            + "|caps=" + circles(f.caps)
            + "|dot=" + optionalCircle(f.dot)
            + "|icon=" + icon(f.icon)
            + "|iconX=" + f.iconX
            + "|iconY=" + f.iconY
            + "|iconColor=" + color(f.iconColor)
            + "|number=" + f.number
            + "|numberColor=" + color(f.numberColor)
            + "|numberFont=" + font(f.numberFont)
            + "|numberWidth=" + f.numberWidth
            + "|numberX=" + f.numberX
            + "|numberY=" + f.numberY;
    }

    function describeBottomField(f as BottomFieldFrame) as String {
        return "pill=" + rect(f.pill)
            + "|icon=" + icon(f.icon)
            + "|iconX=" + f.iconX
            + "|iconY=" + f.iconY
            + "|iconColor=" + color(f.iconColor)
            + "|number=" + f.number
            + "|numberFont=" + font(f.numberFont)
            + "|numberWidth=" + f.numberWidth
            + "|numberX=" + f.numberX
            + "|numberY=" + f.numberY
            + "|numberColor=" + color(f.numberColor)
            + "|goal=" + f.goal
            + "|goalX=" + f.goalX
            + "|goalY=" + f.goalY
            + "|goalColor=" + color(f.goalColor);
    }

    function describeAod(f as AodFrame) as String {
        return "time=" + f.time
            + "|timeX=" + f.timeX
            + "|timeY=" + f.timeY
            + "|timeColor=" + color(f.timeColor)
            + "|date=" + f.date
            + "|dateX=" + f.dateX
            + "|dateY=" + f.dateY
            + "|dateColor=" + color(f.dateColor)
            + "|datePill=" + rect(f.datePill)
            + "|datePillInner=" + rect(f.datePillInner)
            + "|offsetX=" + f.offsetX
            + "|offsetY=" + f.offsetY;
    }

    function describeLayer(l as StaticLayer) as String {
        return "background=" + color(l.backgroundColor)
            + "|edgeMask=" + arc(l.edgeMask)
            + "|bezelTicks=" + describeLines(l.bezelTicks)
            + "|timeBandRim=" + rect(l.timeBandRim)
            + "|fieldRims=" + unordered(circleTexts(l.fieldRims))
            + "|bottomFieldRim=" + rect(l.bottomFieldRim)
            + "|timeBandWell=" + rect(l.timeBandWell)
            + "|timeBand=" + rect(l.timeBand)
            + "|batteryWell=" + arc(l.batteryWell)
            + "|batteryCaps=" + unordered(circleTexts(l.batteryCaps))
            + "|batteryTrack=" + unordered(arcTexts(l.batteryTrack))
            + "|fieldWells=" + unordered(circleTexts(l.fieldWells))
            + "|fieldTracks=" + unordered(arcTexts(l.fieldTracks))
            + "|fieldTrackCaps=" + unordered(circleTexts(l.fieldTrackCaps));
    }

    // The static layer's arrays in sorted order (except the bezel ticks,
    // whose index is their position on the ring): their elements never
    // overlap, so the order they are drawn in does not change a pixel, and
    // the spec keeps tests independent of it.
    function unordered(items as Array<String>) as String {
        for (var i = 1; i < items.size(); i++) {
            var item = items[i];
            var j = i - 1;
            while (j >= 0 && items[j].compareTo(item) > 0) {
                items[j + 1] = items[j];
                j--;
            }
            items[j + 1] = item;
        }
        var text = "{";
        for (var i = 0; i < items.size(); i++) {
            text += items[i];
        }
        return text + "}";
    }

    function arcTexts(list as Array<Arc>) as Array<String> {
        var texts = new Array<String>[list.size()];
        for (var i = 0; i < list.size(); i++) {
            texts[i] = arc(list[i]);
        }
        return texts;
    }

    function circleTexts(list as Array<Circle>) as Array<String> {
        var texts = new Array<String>[list.size()];
        for (var i = 0; i < list.size(); i++) {
            texts[i] = circle(list[i]);
        }
        return texts;
    }

    function describeLines(lines as Array<Line>) as String {
        var text = "[";
        for (var i = 0; i < lines.size(); i++) {
            text += line(lines[i]);
        }
        return text + "]";
    }

    // "--" on a miss, else the field (L, C, R, B, Z for the bezel ring) and
    // the metric (S stress, B Body Battery, H heart rate, P steps).
    function describeTarget(t as LongPressTarget?) as String {
        if (t == null) {
            return "--";
        }
        return fieldCode(t.field) + metricCode(t.metric);
    }

    function fieldCode(field as Field) as String {
        switch (field) {
            case FIELD_LEFT:
                return "L";
            case FIELD_CENTER:
                return "C";
            case FIELD_RIGHT:
                return "R";
            case FIELD_BOTTOM:
                return "B";
            case FIELD_BEZEL_RING:
                return "Z";
        }
        return "?";
    }

    function metricCode(metric as Metric) as String {
        switch (metric) {
            case METRIC_STRESS:
                return "S";
            case METRIC_BODY_BATTERY:
                return "B";
            case METRIC_HEART_RATE:
                return "H";
            case METRIC_STEPS:
                return "P";
        }
        return "?";
    }

    // Arc(x,y,radius,pen,start,end,sweep,color).
    function arc(a as Arc) as String {
        return "A(" + a.x + "," + a.y + "," + a.radius + "," + a.pen + "," + a.start + ","
            + a.end + "," + a.sweep + "," + color(a.color) + ")";
    }

    function arcs(list as Array<Arc>) as String {
        var text = "[";
        for (var i = 0; i < list.size(); i++) {
            text += arc(list[i]);
        }
        return text + "]";
    }

    // RoundedRect(x,y,width,height,radius,color).
    function rect(r as RoundedRect) as String {
        return "R(" + r.x + "," + r.y + "," + r.width + "," + r.height + "," + r.radius + ","
            + color(r.color) + ")";
    }

    // Circle(x,y,radius,color).
    function circle(c as Circle) as String {
        return "C(" + c.x + "," + c.y + "," + c.radius + "," + color(c.color) + ")";
    }

    function circles(list as Array<Circle>) as String {
        var text = "[";
        for (var i = 0; i < list.size(); i++) {
            text += circle(list[i]);
        }
        return text + "]";
    }

    function optionalCircle(c as Circle?) as String {
        return c == null ? "none" : circle(c);
    }

    // Line(x1,y1,x2,y2,pen,color).
    function line(l as Line) as String {
        return "L(" + l.x1 + "," + l.y1 + "," + l.x2 + "," + l.y2 + "," + l.pen + ","
            + color(l.color) + ")";
    }

    function optionalLine(l as Line?) as String {
        return l == null ? "none" : line(l);
    }

    function color(value as Number) as String {
        return value.format("%06X");
    }

    function flag(value as Boolean) as String {
        return value ? "yes" : "no";
    }

    // Every code point as U+XXXX, so the PUA icons stay readable.
    function icon(text as String) as String {
        var out = "";
        var chars = text.toCharArray();
        for (var i = 0; i < chars.size(); i++) {
            out += "U+" + chars[i].toNumber().format("%04X");
        }
        return out;
    }

    function font(value as FontId) as String {
        return FontCatalog.entry(value).name;
    }
}
