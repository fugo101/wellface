import Toybox.Lang;

// Face configs for tests.
(:test)
module TestConfigs {
    // The built-in face config with the mint theme. Tests that check colors
    // or golden values use it, so they hold whichever theme the built-in
    // config names (Q42: switching the face's theme is a one-line change
    // there).
    function mintDefault() as ResolvedFaceConfig {
        var config = FaceConfigs.defaultConfig();
        config.themeName = Themes.MINT;
        return FaceModel.resolve(config);
    }

    // Every face config the fields accept: each round field showing each
    // metric it accepts, the bottom field and the bezel ring their goal
    // metric.
    function accepted() as Array<ResolvedFaceConfig> {
        var configs = [] as Array<ResolvedFaceConfig>;
        var left = FaceModel.acceptedMetrics(FIELD_LEFT);
        var center = FaceModel.acceptedMetrics(FIELD_CENTER);
        var right = FaceModel.acceptedMetrics(FIELD_RIGHT);
        var bottom = FaceModel.acceptedMetrics(FIELD_BOTTOM);
        var bezel = FaceModel.acceptedMetrics(FIELD_BEZEL_RING);
        for (var l = 0; l < left.size(); l++) {
            for (var c = 0; c < center.size(); c++) {
                for (var r = 0; r < right.size(); r++) {
                    for (var b = 0; b < bottom.size(); b++) {
                        for (var z = 0; z < bezel.size(); z++) {
                            configs.add(FaceModel.resolve(new FaceConfig(Themes.MINT, left[l],
                                center[c], right[r], bottom[b], bezel[z])));
                        }
                    }
                }
            }
        }
        return configs;
    }
}
