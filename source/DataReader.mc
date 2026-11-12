import Toybox.Lang;
import Toybox.System;

// Builds the snapshot from the watch's clock and sensors. Thin and untested;
// every display rule lives in FaceModel.
class DataReader {
    private var _snapshot as Snapshot = new Snapshot(0, 0);
    // Minute of the day the sensors were last read, -1 before the first read.
    private var _sensorMinute as Number = -1;
    private var _wasHighPower as Boolean = false;

    // Called on every update that is not OFF. Reads the clock every time.
    // Reads the sensors only in high power, when the minute changed since
    // the last sensor read or the previous update was not high power (that
    // is how a wake is detected). Returns true if the snapshot may have
    // changed, so FaceModel should run again.
    function update(highPower as Boolean) as Boolean {
        var clock = System.getClockTime();
        var changed = clock.hour != _snapshot.hour || clock.min != _snapshot.minute;
        _snapshot.hour = clock.hour;
        _snapshot.minute = clock.min;

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
    }
}
