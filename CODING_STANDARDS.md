# Coding standards

Read during review. These are judgement calls that no tool can check; the mechanical rules live in the build (strict type checking, zero warnings) and in the tests.

## FaceModel is the single test seam

`FaceModel` is pure logic. Its input is a resolved face config, a snapshot (clock, battery, heart-rate zones, each metric's value and goal), the change kinds since the previous frame and the mode (high power or Always On). Its output is everything to draw: strings, colors, arcs, lines, text layout, the lit bezel ticks, the long-press target at a touch point, the read plan and which frame parts a change invalidates. Everything that decides what the face shows goes there, with a test.

- Sensor reading (`DataReader`) and drawing (`Renderer`, `WellfaceView`) stay thin. They follow `FaceModel`'s output and hold no display rule. If a renderer needs an `if` to decide what to show, the decision belongs in `FaceModel`.
- `FaceModel.update` and `updateAod` recompute only the parts a change invalidates, and their result must equal a full `compute` / `computeAod`. A new frame part comes with a test that checks both paths agree (`tests/FrameEquality.mc`).
- Metrics are described once, in the metric module (`source/Metric.mc`). No other module switches on the metric. Field kinds and the drawing styles they accept are in `FieldKinds`.

_Why:_ a watch face is checked by eye in the simulator, which is slow and misses edge cases. Putting the decisions in one pure module makes them testable without a simulator frame.

## Colors only through the theme

Every color on the face comes from the active `Theme`. Layout and logic never name a concrete color; a literal such as `0x8EE3B8` outside `Theme.mc` is a defect. A themed color is derived from the one accent. A color that is the same in every theme (black, white, gray, unlit tracks and ticks, warning and zone colors) is a fixed role of `Theme`, not a literal at its use.

The one exception is the black of Always On, a platform rule (`FaceModel.AOD_BLACK`).

Names, comments, docs and tests do not tie the face to one color: there are ten themes and more may come.

## Performance rules

A face redraws often, and the previous face lagged when returning from menus because it redrew everything every second. These hold for every change to the render path:

- Seconds are drawn only while the face gets per-second updates (high power, between `onExitSleep` and `onEnterSleep`). They are hidden, not frozen, after that. In Always On nothing about seconds is read or drawn.
- A change of the second alone redraws only the seconds and recomputes nothing else.
- Data is read once a minute and on wake. Only heart rate is re-read every second, and only while a field shows it. Nothing is read in Always On but the clock. The read plan in `FaceModel` is the only place that decides this.
- Static parts (background, contour texture, wells, tracks, unlit bezel ticks) are drawn once into the static buffer. The minute layer holds those plus everything that changes at most once a minute; each second it is copied and only what changes every second is drawn over it. Do not draw something every second that changes once a minute.
- Drawing into a buffer is slower than drawing on the screen, so a frame whose minute layer is stale is drawn straight on the screen. When the graphics pool has no room for a buffer, the renderer falls back to a full repaint. Keep that fallback working.
- Fonts are bitmap fonts holding only the glyphs the face draws. A new font or glyph is a change to the generator, not a new file.
- Measure a render-path change before and after (`docs/build.md`, "Profile" and "Timing build"). The per-second update must not get noticeably slower, Always On must not do extra work, and the first frame after returning from a widget must not get slower. Simulator timings are for information only; compare watch timings only with watch timings.

## Fonts and generated files come from the generators

The bitmap fonts in `resources/fonts/`, `source/FontCatalog.mc`, and the contour pieces in `resources/contours/` are generated (`scripts/gen-fonts.sh`, `scripts/gen-contours.sh`). Never edit them by hand. Change the generator, run it again and commit the output. The generator is deterministic; if two runs differ, find out why before committing.

Contour pieces are cut against the wells in `source/Layout.mc`. Change a well or a rim, and regenerate the contours in the same PR. `tests/ContourTest.mc` fails until you do.

A string the face can print must only use glyphs its font holds; `tests/GlyphCoverageTest.mc` checks this. A new string or a new language means checking the glyph set.

Font licenses are kept next to the fonts, and `NOTICE` lists third-party material.

## Strict types and zero warnings

Type checking is strict, set in `monkey.jungle` only, never with a command-line flag. Every build fails on any compiler warning. Do not silence a warning with a cast or an annotation to make a build pass; fix its cause. Use the newest API level the supported device allows, and no deprecated API.

## Tests

- Tests are Monkey C unit tests (`(:test)`) in `tests/`, compiled into test builds only and run in the simulator with `scripts/run-tests.sh`.
- The golden values (`tests/GoldenValues.mc`) pin the default face. A golden value is re-recorded only for an intended change to what is drawn, and the new value is checked against an independent computation (from the design or by hand), not taken from the code's own output. Say in the PR what changed and why.
- Test configs name their theme explicitly, so tests hold whichever theme the built-in face config names.
- A bug fix comes with a test that fails without it.

_Why:_ a golden value copied from the code under test proves only that the code equals itself.

## Always On and burn-in

Always On is an AMOLED low-power mode. The SDK's rule for newer AMOLED watches is less than 10% of the screen's luminance; breaking it makes the watch turn the screen off. Which rule a given watch's firmware enforces is not documented, so the simulator's heat map decides (File → View Screen Heat Map, with low-power mode on; menu names may differ slightly). A change that adds anything to Always On is checked with it, and the number goes into the PR. The time and date keep their per-minute shift of a few pixels to limit physical burn-in.

## Adding a device

A new device is additive. It must not change a single pixel on the Forerunner 265: the Forerunner 265 golden tests stay unchanged, and a capture comparison shows no difference. Anything a device needs that others do not (a different screen size, a different API level) is data for that device, not a branch inside shared drawing code. See [`CONTRIBUTING.md`](CONTRIBUTING.md#device-support) for what else a port needs.

## Commits, issues and docs

- Commit messages and PR titles are [Conventional Commits](https://www.conventionalcommits.org/). A commit holds one topic.
- Everything in the repo is in English, and holds no personal data: no names, emails, machine paths, or numbers from a personal watch.
- A design decision lives in `docs/decisions.md` and changes only with the maintainer's agreement. Where the built face departs from the design, add a row to `docs/design-sync.md`.
- Never commit the developer key, or anything from the Garmin SDK or device files.
