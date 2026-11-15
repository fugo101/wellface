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
    // What to read in high power, from the applied face config.
    private var _plan as ReadPlan = new ReadPlan([] as Array<Metric>, [] as Array<Metric>, false);
    // The complication id of each metric read from a complication, indexed
    // by metric (null for the others).
    private var _ids as Array<Complications.Id?>;

    function initialize() {
        var all = Metrics.ALL;
        _ids = new Array<Complications.Id?>[all.size()];
        for (var i = 0; i < all.size(); i++) {
            var entry = Metrics.entry(all[i]);
            if (entry.source == SOURCE_COMPLICATION) {
                _ids[all[i]] = new Complications.Id(entry.complication);
            }
        }
    }

    // Reads what the face shows from now on (FaceModel.readPlan), and makes
    // the next high-power update count as a wake, so every metric in the
    // plan (and the zones, if needed) is read before the next frame. Called
    // by the apply-config path.
    function setReadPlan(plan as ReadPlan) as Void {
        _plan = plan;
        countNextUpdateAsWake();
    }

    // Called on every update that is not OFF; returns what changed in the
    // snapshot since the previous call (ChangeKind bits, 0 for nothing).
    //
    // The clock: the cheap system clock is read every time; only when its
    // hour or minute differs from the snapshot's is the full calendar read,
    // and the hour, minute, date and weekday all come from that one reading
    // (no 23:59 with the next day's date). The weekday name is read with it,
    // so a change of watch language is followed within a minute.
    //
    // The clock's second, in high power only (Q41): taken from the same
    // clock reading while the face gets per-second updates (`ticking`), and
    // null while it sleeps with the screen still lit; a change of it is
    // CHANGE_SECOND. In AOD the snapshot keeps its last second, so the first
    // update after a wake reports CHANGE_SECOND unless the clock is on that
    // same second again (then the frame already shows it).
    //
    // The sensors, in high power only (nothing is read in AOD, Q36): the
    // battery and the plan's once-a-minute metrics when the minute changed
    // since the last sensor read or the previous update was not high power
    // (that is how a wake is detected; the first high-power update after
    // start or a new read plan counts as one), the zones on a wake when the
    // plan needs them, and the plan's every-second metrics (heart rate) on
    // every high-power update. A value read again unchanged is no change.
    function update(highPower as Boolean, ticking as Boolean) as Number {
        var changes = 0;
        var clock = System.getClockTime();
        if (!_clockRead || clock.hour != _snapshot.hour || clock.min != _snapshot.minute) {
            changes |= readCalendar();
        }

        if (highPower) {
            var second = ticking ? clock.sec : null;
            if (second != _snapshot.second) {
                _snapshot.second = second;
                changes |= CHANGE_SECOND;
            }
            var wake = !_wasHighPower;
            var minuteOfDay = _snapshot.hour * 60 + _snapshot.minute;
            if (wake && _plan.zones) {
                var zones = readHeartRateZones();
                if (!sameNumbers(zones, _snapshot.heartRateZones)) {
                    _snapshot.heartRateZones = zones;
                    changes |= CHANGE_MINUTE_DATA;
                }
            }
            if (wake || minuteOfDay != _sensorMinute) {
                _sensorMinute = minuteOfDay;
                if (readMinuteData()) {
                    changes |= CHANGE_MINUTE_DATA;
                }
            }
            var everySecond = _plan.everySecond;
            for (var i = 0; i < everySecond.size(); i++) {
                // Every per-second metric is a complication (heart rate).
                var metric = everySecond[i];
                if (setValue(metric, readComplication(_ids[metric]))) {
                    changes |= CHANGE_PER_SECOND;
                }
            }
        }
        _wasHighPower = highPower;
        return changes;
    }

    // Makes the next high-power update count as a wake, so it reads every
    // metric of the plan and the zones even within the same minute. Called
    // when the screen is OFF and with a new read plan.
    function countNextUpdateAsWake() as Void {
        _wasHighPower = false;
    }

    function snapshot() as Snapshot {
        return _snapshot;
    }

    // The full calendar reading: hour, minute, date and weekday from one
    // moment, and the weekday name. Returns CHANGE_CLOCK if any of them
    // changed, else 0.
    private function readCalendar() as Number {
        var now = Time.now();
        // Info.hour is 0-23 whatever the 12/24 h setting (Q22).
        var info = Gregorian.info(now, Time.FORMAT_SHORT);
        var weekdayNumber = info.day_of_week as Number;
        // FORMAT_SHORT gives the month as a Number, 1-12.
        var month = info.month as Number;
        var name = Gregorian.info(now, Time.FORMAT_MEDIUM).day_of_week;
        var weekdayName = name instanceof String ? name : null;
        var s = _snapshot;
        var changed = !_clockRead || info.hour != s.hour || info.min != s.minute
            || info.day != s.day || month != s.month || weekdayNumber != s.weekdayNumber
            || !sameText(weekdayName, s.weekdayName);
        s.hour = info.hour;
        s.minute = info.min;
        s.day = info.day;
        s.month = month;
        s.weekdayNumber = weekdayNumber;
        s.weekdayName = weekdayName;
        _clockRead = true;
        return changed ? CHANGE_CLOCK : 0;
    }

    // The battery and every metric the plan reads once a minute. Returns
    // true if any of them changed.
    private function readMinuteData() as Boolean {
        // A Float percentage; FaceModel only sees a whole number in 0-100.
        var battery = FaceModel.clamp((System.getSystemStats().battery + 0.5).toNumber(), 0, 100);
        var changed = battery != _snapshot.battery;
        _snapshot.battery = battery;

        var everyMinute = _plan.everyMinute;
        for (var i = 0; i < everyMinute.size(); i++) {
            var metric = everyMinute[i];
            if (Metrics.entry(metric).source == SOURCE_COMPLICATION) {
                changed = setValue(metric, readComplication(_ids[metric])) || changed;
            } else if (Metrics.entry(metric).source == SOURCE_ACTIVITY_STEPS) {
                // Both may be null; the goal is the watch's own (auto) goal.
                var activity = ActivityMonitor.getInfo();
                changed = setValue(metric, wholeNumber(activity.steps)) || changed;
                changed = setGoal(metric, wholeNumber(activity.stepGoal)) || changed;
            }
        }
        return changed;
    }

    // Sets a metric's value; true if it changed.
    private function setValue(metric as Metric, value as Number?) as Boolean {
        if (value == _snapshot.value(metric)) {
            return false;
        }
        _snapshot.setValue(metric, value);
        return true;
    }

    // Sets a goal metric's goal; true if it changed.
    private function setGoal(metric as Metric, goal as Number?) as Boolean {
        if (goal == _snapshot.goal(metric)) {
            return false;
        }
        _snapshot.setGoal(metric, goal);
        return true;
    }

    private function sameText(a as String?, b as String?) as Boolean {
        return a == null || b == null ? a == b : a.equals(b);
    }

    private function sameNumbers(a as Array<Number>?, b as Array<Number>?) as Boolean {
        if (a == null || b == null) {
            return a == b;
        }
        if (a.size() != b.size()) {
            return false;
        }
        for (var i = 0; i < a.size(); i++) {
            if (a[i] != b[i]) {
                return false;
            }
        }
        return true;
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
