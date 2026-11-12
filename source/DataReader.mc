import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;

// Builds the snapshot from the watch's clock and sensors. Thin and untested;
// every display rule lives in FaceModel.
class DataReader {
    private var _snapshot as Snapshot = new Snapshot(0, 0);
    private var _clockRead as Boolean = false;
    // Minute of the day the sensors were last read, -1 before the first read.
    private var _sensorMinute as Number = -1;
    private var _wasHighPower as Boolean = false;
    private var _bodyBatteryId as Complications.Id =
        new Complications.Id(Complications.COMPLICATION_TYPE_BODY_BATTERY);
    private var _stressId as Complications.Id =
        new Complications.Id(Complications.COMPLICATION_TYPE_STRESS);

    // Called on every update that is not OFF. Reads the clock and date
    // every time, from one moment so they always agree (no 23:59 with the
    // next day's date), and the weekday name only when they changed.
    // Reads the sensors only in high power, when the minute changed since
    // the last sensor read or the previous update was not high power (that
    // is how a wake is detected). Returns true if the snapshot may have
    // changed, so FaceModel should run again.
    function update(highPower as Boolean) as Boolean {
        var now = Time.now();
        // Info.hour is 0-23 whatever the 12/24 h setting (Q22).
        var clock = Gregorian.info(now, Time.FORMAT_SHORT);
        var weekdayNumber = clock.day_of_week as Number;
        var changed = !_clockRead || clock.hour != _snapshot.hour
            || clock.min != _snapshot.minute || clock.day != _snapshot.day
            || weekdayNumber != _snapshot.weekdayNumber;
        _snapshot.hour = clock.hour;
        _snapshot.minute = clock.min;
        _snapshot.day = clock.day;
        _snapshot.weekdayNumber = weekdayNumber;
        if (changed) {
            // Once a minute is enough to follow a change of watch language.
            var name = Gregorian.info(now, Time.FORMAT_MEDIUM).day_of_week;
            _snapshot.weekdayName = name instanceof String ? name : null;
            _clockRead = true;
        }

        var minuteOfDay = clock.hour * 60 + clock.min;
        if (highPower && (minuteOfDay != _sensorMinute || !_wasHighPower)) {
            readSensors();
            _sensorMinute = minuteOfDay;
            changed = true;
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

    private function readSensors() as Void {
        // A Float percentage; FaceModel only sees a whole number in 0-100.
        var battery = (System.getSystemStats().battery + 0.5).toNumber();
        _snapshot.battery = FaceModel.clamp(battery, 0, 100);

        // Both may be null; the goal is the watch's own (auto) goal.
        var activity = ActivityMonitor.getInfo();
        _snapshot.steps = activity.steps;
        _snapshot.stepGoal = activity.stepGoal;

        _snapshot.bodyBattery = readComplication(_bodyBatteryId);
        _snapshot.stress = readComplication(_stressId);
    }

    // A complication's value, polled (ticket 02 showed polling refreshes on
    // the FR265). Null when it throws or is not a non-negative Number.
    private function readComplication(id as Complications.Id) as Number? {
        try {
            var value = Complications.getComplication(id).value;
            if (value instanceof Number && value >= 0) {
                return value;
            }
        } catch (e instanceof Lang.Exception) {
            // Missing, like a null value.
        }
        return null;
    }
}
