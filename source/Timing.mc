import Toybox.Lang;
import Toybox.System;

// Wall-clock timings of the face's own work, for the timing build only
// (scripts/build-timing.sh; docs/build.md, "Timing build"). Normal builds
// exclude the (:timing) module below and get the (:notiming) one, whose
// calls do nothing; the timing build (timing.jungle) swaps them.
//
// Readings are kept in memory and printed only when the face enters AOD
// (onEnterSleep), the view is hidden, the app stops, or the buffer is
// nearly full at the end of an update, so no print falls inside a timed
// part. On the watch System.println writes to GARMIN/Apps/LOGS/WELLFACE.TXT
// (the file must exist), and the watch moves it to WELLFACE.BAK once it
// passes about 5 kB, so the output is kept short; tools/timing/summary.py
// reads it.

// What a reading times. Start and stop a timing with the same kind; a stop
// of TIMING_UPDATE or TIMING_AOD is recorded as TIMING_FIRST,
// TIMING_FIRST_AOD, TIMING_SHOW or TIMING_WAKE when it is the first update
// since the face started, since the view was hidden, or since AOD. An
// update's time includes the frame and static readings taken inside it.
enum TimingKind {
    // A high-power update (WellfaceView.onUpdate after the mode check).
    TIMING_UPDATE,
    // An AOD update.
    TIMING_AOD,
    // The first update after a face start, in high power.
    TIMING_FIRST,
    // The first update after a face start, in AOD.
    TIMING_FIRST_AOD,
    // The first high-power update after AOD or a screen off (a wake).
    TIMING_WAKE,
    // The first high-power update after the view was hidden and shown
    // again without a restart (a return from the widget loop).
    TIMING_SHOW,
    // FaceModel.update on its own.
    TIMING_FRAME,
    // FaceModel.updateAod on its own.
    TIMING_AOD_FRAME,
    // The static layer paint (Renderer.paintStatic).
    TIMING_STATIC,
    // A rebuild of the minute layer: the static buffer copied into the
    // minute buffer, then every part that changes at most once a minute.
    TIMING_MINUTE,
    // A high-power update while the face sleeps (after onEnterSleep, the
    // screen still lit, once a minute). Never filed under another kind.
    TIMING_ASLEEP,
    // The contour texture alone, drawn with lines on the screen (the frame
    // after a face start) and into the static buffer.
    TIMING_CONTOURS,
    TIMING_CONTOURS_BUFFER,
}

(:notiming)
module Timing {
    function start(kind as TimingKind) as Void {
    }

    function stop(kind as TimingKind) as Void {
    }

    function flush(reason as String) as Void {
    }
}

(:timing)
module Timing {
    // The one-letter code printed before each reading's milliseconds, in
    // TimingKind order (tools/timing/summary.py reads them, and also the
    // codes of a strip trial, no longer recorded).
    const CODES = ["u", "a", "F", "A", "w", "h", "f", "d", "s", "m", "i", "c", "b"];
    // Readings kept before a flush; an update adds at most three.
    const CAPACITY = 240;
    // Readings per printed line.
    const PER_LINE = 20;

    // Each reading is ms * KIND_RANGE + kind.
    const KIND_RANGE = 16;
    var _readings as Array<Number> = new Array<Number>[CAPACITY];
    var _count as Number = 0;
    // System.getTimer() at the last start of each kind.
    var _starts as Array<Number> = new Array<Number>[CODES.size()];
    // No update recorded since the face started (module variables start
    // fresh with the app) or since the view was hidden, and whether the
    // last update recorded was high power.
    var _fresh as Boolean = true;
    var _hidden as Boolean = false;
    var _lastHighPower as Boolean = false;

    function start(kind as TimingKind) as Void {
        _starts[kind] = System.getTimer();
    }


    function stop(kind as TimingKind) as Void {
        var ms = System.getTimer() - _starts[kind];
        var update = kind == TIMING_UPDATE || kind == TIMING_AOD;
        var recorded = kind;
        if (update) {
            var highPower = kind == TIMING_UPDATE;
            if (_fresh) {
                recorded = highPower ? TIMING_FIRST : TIMING_FIRST_AOD;
            } else if (highPower && _hidden) {
                recorded = TIMING_SHOW;
            } else if (highPower && !_lastHighPower) {
                recorded = TIMING_WAKE;
            }
            _fresh = false;
            _hidden = false;
            _lastHighPower = highPower;
        }
        // The subtraction wraps like the timer, so a span across a rollover
        // is still right; a negative one cannot be packed and is dropped.
        if (ms >= 0 && _count < CAPACITY) {
            _readings[_count] = ms * KIND_RANGE + recorded;
            _count++;
        }
        // Only at the end of an update, so the print is not timed.
        if (update && _count > CAPACITY - 3) {
            flush("full");
        }
    }

    // Prints a header line ("timing flush <reason> <count>") and the
    // readings kept, PER_LINE to a line ("timing u19 f4 u23"), then forgets
    // them. Reasons: "sleep" (entering AOD; the screen goes off only from
    // there, so the next high-power update is a wake), "hide" (the next one
    // is a show), "stop" and "full".
    function flush(reason as String) as Void {
        if (reason.equals("sleep")) {
            _lastHighPower = false;
        } else if (reason.equals("hide")) {
            _hidden = true;
        }
        System.println("timing flush " + reason + " " + _count);
        var line = "timing";
        for (var i = 0; i < _count; i++) {
            var reading = _readings[i];
            line += " " + CODES[reading % KIND_RANGE] + reading / KIND_RANGE;
            if ((i + 1) % PER_LINE == 0 || i == _count - 1) {
                System.println(line);
                line = "timing";
            }
        }
        _count = 0;
    }
}
