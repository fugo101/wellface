// The health and activity data a field can show (Q29). The metric, not the
// field, decides how its value is drawn: stress and Body Battery as a gauge,
// heart rate as zone segments, steps as progress toward the goal.
enum Metric {
    METRIC_STRESS,
    METRIC_BODY_BATTERY,
    METRIC_HEART_RATE,
    METRIC_STEPS
}
