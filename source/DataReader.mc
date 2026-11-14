import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.UserProfile;

// Builds the snapshot from the watch's clock and sensors. Thin and untested;
// every display rule lives in FaceModel.
class DataReader {
    private var _snapshot as Snapshot = new Snapshot(0, 0);
    private var _clockRead as Boolean = false;
    // Minute of the day the sensors were last read, -1 before the first read.
    private var _sensorMinute as Number = -1;
    private var _wasHighPower as Boolean = false;
    // The complication id of each metric read from a complication, indexed
    // by metric (null for the others).
    private var _ids as Array<Complications.Id?>;

    function initialize() {
        var all = Metrics.ALL;
        _ids = new Array<Complications.Id?>[all.size()];
        for (var i = 0; i < all.size(); i++) {
            var entry = Metrics.entry(all[i]);
            if (entry.source == SOURCE_COMPLICATION) {
                _ids[i] = new Complications.Id(entry.complication);
            }
        }
    }

    // Called on every update that is not OFF. Reads the clock and date
    // every time, from one moment so they always agree (no 23:59 with the
    // next day's date), and the weekday name only when they changed.
    // Reads the sensors only in high power: the battery and every metric read
    // once a minute (Metrics), when the minute changed since the last sensor
    // read or the previous update was not high power (that is how a wake is
    // detected; the first high-power update after start counts as one). On
    // a wake it also reads the heart-rate zones (always for now; the read
    // plan of ticket 04 limits it to a face that draws zone segments). The
    // metrics read every second (heart rate, Q36) are read on every
    // high-power update. Nothing is read in AOD. Returns true if the
    // snapshot may have changed, so FaceModel should run again; a per-second
    // value that did not change does not count.
    function update(highPower as Boolean) as Boolean {
        var now = Time.now();
        // Info.hour is 0-23 whatever the 12/24 h setting (Q22).
        var clock = Gregorian.info(now, Time.FORMAT_SHORT);
        var weekdayNumber = clock.day_of_week as Number;
        // FORMAT_SHORT gives the month as a Number, 1-12.
        var month = clock.month as Number;
        var changed = !_clockRead || clock.hour != _snapshot.hour
            || clock.min != _snapshot.minute || clock.day != _snapshot.day
            || month != _snapshot.month || weekdayNumber != _snapshot.weekdayNumber;
        _snapshot.hour = clock.hour;
        _snapshot.minute = clock.min;
        _snapshot.day = clock.day;
        _snapshot.month = month;
        _snapshot.weekdayNumber = weekdayNumber;
        if (changed) {
            // Once a minute is enough to follow a change of watch language.
            var name = Gregorian.info(now, Time.FORMAT_MEDIUM).day_of_week;
            _snapshot.weekdayName = name instanceof String ? name : null;
            _clockRead = true;
        }

        if (highPower) {
            var wake = !_wasHighPower;
            var minuteOfDay = clock.hour * 60 + clock.min;
            if (wake) {
                _snapshot.heartRateZones = readHeartRateZones();
            }
            if (wake || minuteOfDay != _sensorMinute) {
                readSensors();
                _sensorMinute = minuteOfDay;
                changed = true;
            }
            var all = Metrics.ALL;
            for (var i = 0; i < all.size(); i++) {
                var metric = all[i];
                var entry = Metrics.entry(metric);
                // Every per-second metric is a complication (heart rate).
                if (entry.cadence == CADENCE_EVERY_SECOND
                        && entry.source == SOURCE_COMPLICATION) {
                    var value = readComplication(_ids[i]);
                    if (value != _snapshot.value(metric)) {
                        _snapshot.setValue(metric, value);
                        changed = true;
                    }
                }
            }
        }
        _wasHighPower = highPower;
        return changed;
    }

    // Called when the screen is OFF, so the next high-power update counts
    // as a wake and reads the sensors even within the same minute.
    function screenOff() as Void {
        _wasHighPower = false;
    }

    function snapshot() as Snapshot {
        return _snapshot;
    }

    // The battery and every metric read once a minute.
    private function readSensors() as Void {
        // A Float percentage; FaceModel only sees a whole number in 0-100.
        var battery = (System.getSystemStats().battery + 0.5).toNumber();
        _snapshot.battery = FaceModel.clamp(battery, 0, 100);

        var all = Metrics.ALL;
        for (var i = 0; i < all.size(); i++) {
            var metric = all[i];
            var entry = Metrics.entry(metric);
            if (entry.cadence != CADENCE_EVERY_MINUTE) {
                continue;
            }
            if (entry.source == SOURCE_COMPLICATION) {
                _snapshot.setValue(metric, readComplication(_ids[i]));
            } else if (entry.source == SOURCE_ACTIVITY_STEPS) {
                // Both may be null; the goal is the watch's own (auto) goal.
                var activity = ActivityMonitor.getInfo();
                _snapshot.setValue(metric, wholeNumber(activity.steps));
                _snapshot.setGoal(metric, wholeNumber(activity.stepGoal));
            }
        }
    }

    // The value if it is a whole number (a Number), else null. Negative
    // values are kept: FaceModel applies the invalid-value rule.
    private function wholeNumber(value as Object?) as Number? {
        return value instanceof Number ? value : null;
    }

    // The lower bounds of zones 1-5: the first five HR_ZONE_SPORT_GENERIC
    // thresholds (index 5 is max HR). Null when the call fails or returns
    // fewer than five.
    private function readHeartRateZones() as Array<Number>? {
        try {
            var all = UserProfile.getHeartRateZones(UserProfile.HR_ZONE_SPORT_GENERIC);
            var count = Layout.ZONE_SEGMENTS;
            if (all != null && all.size() >= count) {
                return all.slice(0, count);
            }
        } catch (e instanceof Lang.Exception) {
            // Missing, like a short array.
        }
        return null;
    }

    // A complication's value, polled (ticket 02 showed polling refreshes on
    // the FR265). Null when there is no id, when it throws or when the value
    // is not a whole number (the API also allows a Float or a String).
    private function readComplication(id as Complications.Id?) as Number? {
        if (id == null) {
            return null;
        }
        try {
            return wholeNumber(Complications.getComplication(id).value);
        } catch (e instanceof Lang.Exception) {
            // Missing, like a null value.
        }
        return null;
    }
}
