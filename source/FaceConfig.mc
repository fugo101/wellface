import Toybox.Lang;

// The face config (glossary): the name of a theme and the metric shown in
// each field. A plain value, so settings only need to build one; FaceModel
// resolves it before anything uses it. It may ask for an unknown theme or
// for a metric a field cannot draw.
class FaceConfig {
    public var themeName as String;
    // Indexed by field.
    private var _metrics as Array<Metric>;

    function initialize(themeName as String, left as Metric, center as Metric, right as Metric,
            bottom as Metric, bezelRing as Metric) {
        self.themeName = themeName;
        _metrics = [left, center, right, bottom, bezelRing] as Array<Metric>;
    }

    function metricOf(field as Field) as Metric {
        return _metrics[field];
    }
}

// A face config after FaceModel.resolve: a known theme, and in each field a
// metric its field kind accepts (Q40). The same metric may be in several
// fields, as steps is on the bottom field and the bezel ring. Every
// FaceModel entry point takes one.
class ResolvedFaceConfig {
    public var theme as Theme;
    // Indexed by field.
    private var _metrics as Array<Metric>;

    function initialize(theme as Theme, metrics as Array<Metric>) {
        self.theme = theme;
        _metrics = metrics;
    }

    function metricOf(field as Field) as Metric {
        return _metrics[field];
    }
}

module FaceConfigs {
    // The built-in face config: today's face (Q29). Its metric in each field
    // is that field's default metric, which a field shows instead of one it
    // cannot draw (Q40). Its theme is the active theme the wearer picked
    // (Q42: switching it is this one line); the default theme an unknown name
    // falls back to stays Mint (Q9, Themes.mint).
    function defaultConfig() as FaceConfig {
        return new FaceConfig(Themes.PLATINUM, METRIC_STRESS, METRIC_BODY_BATTERY,
            METRIC_HEART_RATE, METRIC_STEPS, METRIC_STEPS);
    }
}
