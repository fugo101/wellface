import Toybox.Lang;
import Toybox.Test;

// The minute layer (Q44): everything drawn that changes at most
// once a minute. The renderer rebuilds it only when a set of change kinds
// makes one of its parts stale; FaceModel answers that, so the rule is
// tested here and the renderer only follows it.
(:test)
module MinuteLayerTest {
    // A second, a heart-rate change, or both, never make the minute layer
    // stale, in any accepted face config: each second only the seconds and
    // the field showing heart rate are drawn over it.
    (:test)
    function perSecondChangesKeepTheMinuteLayer(logger as Test.Logger) as Boolean {
        var configs = TestConfigs.accepted();
        var kinds = [0, CHANGE_SECOND, CHANGE_PER_SECOND, CHANGE_SECOND | CHANGE_PER_SECOND]
            as Array<Number>;
        for (var i = 0; i < configs.size(); i++) {
            for (var k = 0; k < kinds.size(); k++) {
                Test.assertEqualMessage(false, FaceModel.minuteLayerChanged(kinds[k], configs[i]),
                    "config " + i + ", changes " + kinds[k]);
            }
        }
        return true;
    }

    // A clock change (the time and date) or the minute data (battery,
    // steps, Body Battery, stress, zones), alone or with a per-second
    // change, makes it stale in every accepted face config.
    (:test)
    function minuteChangesRebuildTheMinuteLayer(logger as Test.Logger) as Boolean {
        var configs = TestConfigs.accepted();
        var kinds = [CHANGE_CLOCK, CHANGE_MINUTE_DATA, CHANGE_CLOCK | CHANGE_SECOND,
            CHANGE_MINUTE_DATA | CHANGE_PER_SECOND | CHANGE_SECOND, CHANGE_ALL] as Array<Number>;
        for (var i = 0; i < configs.size(); i++) {
            for (var k = 0; k < kinds.size(); k++) {
                Test.assertEqualMessage(true, FaceModel.minuteLayerChanged(kinds[k], configs[i]),
                    "config " + i + ", changes " + kinds[k]);
            }
        }
        return true;
    }
}
