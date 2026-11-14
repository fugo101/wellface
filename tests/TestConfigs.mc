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
}
