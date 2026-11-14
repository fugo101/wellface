# Build, test and sideload

All commands run from the repo root. The scripts find the SDK that the Connect IQ SDK Manager marked as current (override with `CIQ_SDK=<sdk folder>`), and need `java` on `PATH`.

## Developer key

Every build is signed with your developer key (RSA 4096, DER). Keep it outside the repo and point `CIQ_DEV_KEY` at it, for example in your shell profile:

```sh
export CIQ_DEV_KEY="<path to your developer key>"
```

The scripts never print the key or its path. If the VS Code extension generated the key, its path is in the `monkeyC.developerKeyPath` user setting.

## Commands

| Script | Output | Use |
|---|---|---|
| `scripts/build-debug.sh` | `bin/wellface.prg` | debug build |
| `scripts/run-sim.sh` | `bin/wellface.prg` | debug build, start the simulator and load the face |
| `scripts/build-test.sh` | `bin/wellface-test.prg` | build with the `(:test)` code |
| `scripts/run-tests.sh [test name]` | `bin/test.log` | build the tests, start the simulator, run them |
| `scripts/build-release.sh` | `bin/wellface-release.prg` | release build for the watch (`-r --build-stats 0`) |
| `scripts/build-profile.sh` | `bin/wellface-profile.prg` | the release build with profiling support (`-r -k`), see "Profile" |
| `scripts/run-profile.sh [file.prg]` | `bin/wellface-profile.prg` | profile build (or the given PRG), start the simulator and load it |
| `scripts/capture.sh <dir> [--compare <dir>]` | `<dir>/<scenario>.png` | simulator screenshots of fixed scenarios, compared pixel by pixel, see "Captures" |
| `scripts/sideload.sh [file.prg]` | `GARMIN/Apps/WELLFACE.PRG` on the watch | release build, then copy it to the watch over USB (or copy the given PRG) |
| `scripts/gen-fonts.sh` | `resources/fonts/`, `source/FontCatalog.mc` | regenerate the bitmap fonts, the icon font and the font catalog |
| `scripts/build-spike.sh` | `bin/wfspike.prg` | data spike (ticket 02), a separate debug-only face |
| `scripts/run-spike.sh` | `bin/wfspike.prg` | data spike, start the simulator and load it |

Every build fails on any compiler warning. Type checking is strict, set in each jungle (`monkey.jungle`, `spikes/data/monkey.jungle`).

`sideload.sh` exits 0 when exactly one full-size copy is confirmed on the watch, 1 when the copy is not confirmed and 2 when it could not run (no watch, an MTP app holding it, missing tools, failed build).

`run-tests.sh` exits 0 when all tests pass, 1 when a test fails and 2 when the tests could not run (the build failed, or there is no `RESULTS` block because the simulator was not reachable, the app crashed or the run timed out). It ignores `monkeydo`'s exit code, which is 1 even when every test passes (SDK 9.3.0).

## Fonts

`scripts/gen-fonts.sh` runs the font generator (`tools/fontgen/generate.py`). It downloads the source fonts fresh from Google Fonts (the google/fonts repository, so it needs the network) and rewrites everything in `resources/fonts/` (BMFont `.fnt` + PNG pages, `fonts.xml`, the OFL license files) and `source/FontCatalog.mc`, the font catalog: one entry per font, the icon font included, with its resource, glyph set, glyph widths (the `.fnt` xadvances), base, cap height and letter spacing. FaceModel measures text and the renderer loads and draws fonts through the same entry, and a glyph-coverage test (`tests/GlyphCoverageTest.mc`) fails if any string the face can print uses a glyph its font lacks. It reads google/fonts at the latest commit on `main` (Q31). To rebuild exactly the fonts of an earlier commit, set `GOOGLE_FONTS_COMMIT=<sha>`; the fonts in the repo were generated from `29b4ec6df2522a8aee279414b78a07910b065874` (2026-11-13), and regenerating from it, or from `main` while upstream is unchanged, leaves `resources/fonts/` byte-identical. Never edit those files by hand; change the `FONTS` list (or `ICONS`, for the icon font) in the generator and run the script again. Commit the generated files.

The first run creates a gitignored `.venv/` with Python 3.15 (override with `PYTHON=<interpreter>`) and the pinned versions in `tools/fontgen/requirements.txt`. The generator fails if a requested glyph is missing from a source font, if the time font's `0` is not 63 px ± 1 tall, if a digit's ink does not fit its tabular cell, or if an asserted advance (`0` 38 px, `:` 19 px) differs.

## Run in the simulator

`scripts/run-sim.sh` builds, starts the simulator and loads the face. It stays attached and prints the face's log; press Ctrl+C to stop it.

To try a long press, hold the left mouse button on a field for about a second. The simulator shows a plain launch view (for example "Body Battery launched") instead of a Garmin page; File → Kill App, then `scripts/run-sim.sh` again, brings the face back.

To check Always On, choose Settings → Display Mode → Always-On in the simulator (High Power switches back), then File → View Screen Heat Map. The heat map window shows the current luminance usage, and its 24-Hour Simulation reports the peak luminance usage and whether burn-in was detected (simulator of SDK 9.3.0).

## Profile

`scripts/build-profile.sh` builds the release build with profiling support (`-k`). `scripts/run-profile.sh` builds it, starts the simulator and loads it; give it a PRG to load that one instead (for example a baseline build of an older commit). With SDK 9.3.0 the simulator opens its profiler window (File → View Profiler) by itself when such a build loads. The profiler lists Function, Total Time, Actual Time, Average Time (µs) and Call Count (Garmin's profiling guide).

The measurement scenario is fixed (`.scratch/settings-ready/spec.md`, refresh plan), so numbers stay comparable from one change to the next:

1. Load the default face with `scripts/run-profile.sh`.
2. Simulation → Activity Data → Data Source: Data Simulation. Heart rate then changes about every second.
3. Awake: profile 30 s in Settings → Display Mode → High Power. Note the Average Time of `WellfaceView.onUpdate` (the high-power update), `FaceModel.compute` (the frame) and `DataReader.readComplication` (mostly the heart-rate read: it runs every second, the other two complications once a minute).
4. Always On: Settings → Display Mode → Always-On, profile 3 minutes. Note the Average Time of `WellfaceView.onUpdate` (the AOD update) and `FaceModel.computeAod`.
5. Peak memory: File → View Memory.
6. Run the whole scenario twice; the spread between the two runs is the profiler's noise.

How to start, stop and read a profiling run is not settled yet: driven by scripted clicks in this session, the table stayed empty (simulator of SDK 9.3.0). Menu names may differ slightly.

On the watch, Garmin's guide says a build with profiling support writes `GARMIN/APPS/LOGS/<app>.PRF`, which the profiler's Load button opens together with the build's `.prg.debug.xml`. Whether the FR265 does this, and whether the file must exist first (as the `.TXT` log must), is not verified.

## Captures

`scripts/capture.sh <dir>` takes simulator screenshots of the face in fixed scenarios: `normal`, `missing` (no data), `goalReached`, `longSteps` (12.345 of 15.000), `steps100000`, `warning` (level 2 everywhere, heart rate in zone 5) and `aod`. It builds the capture face (`tools/capture/`: the face's own FaceModel, Renderer, fonts and resources, fed a fixed snapshot instead of sensors) once per scenario, loads it and captures the simulator window. With `--compare <dir>` it then compares each capture with the one of the same name in that folder, pixel by pixel (the window's title bar and status bar left out). It exits 0 when everything was captured (and, with `--compare`, every capture is identical), 1 when a capture differs or is missing, and 2 when it could not run (build failed, no simulator, missing permission). Two runs of the same build give identical captures.

Captures are machine-specific (display scale, simulator version), so compare only captures taken on the same Mac. Keep them in the gitignored `captures/` folder. It needs macOS and the Screen Recording permission for the terminal, and `.venv` (created by `scripts/gen-fonts.sh`) for `--compare`.

## Data spike

`spikes/data/` is a separate debug-only face (own jungle, manifest and app id) that shows raw sensor values as plain text: Body Battery, stress and heart rate polled from complications, steps and the step goal, the `HR_ZONE_SPORT_GENERIC` zones and the `FORMAT_MEDIUM` weekday with its code points. Each value shows the clock time it last changed. Nothing in it is part of `monkey.jungle`, so it never reaches the release build.

It shows up on the watch as its own face, "Wellface data spike", next to Wellface. Sideload `bin/wfspike.prg` like the release PRG below. To also keep a log of every change on the watch, create an empty file `GARMIN/APPS/LOGS/WFSPIKE.TXT` before unplugging (Garmin's debugging guide: the log file must exist and match the PRG name). In the simulator, `run-spike.sh` does not print the log (seen with SDK 9.3.0).

## Sideload to the watch

One-time setup: install libmtp (on macOS: `brew install libmtp`). A C compiler is needed too (on macOS: the Xcode Command Line Tools). `sideload.sh` finds libmtp through `pkg-config` or Homebrew, so no path is configured.

1. Fully quit Garmin Express and any MTP client (OpenMTP): only one program can hold the watch's USB connection.
2. Connect the watch with the cable and run `scripts/sideload.sh`. It builds the release PRG, compiles the MTP helper `bin/mtp-push` from `tools/sideload/mtp_push.c` the first time (or after the source changes), removes any `WELLFACE.PRG` still waiting in `GARMIN/Apps`, sends the new one, and checks in a fresh MTP session that exactly one full-size copy is there.
3. Unplug the watch and choose Wellface from the watch-face list (menu names may differ slightly).

The helper works around three FR265 MTP quirks: the watch rejects storage id 0 (so the stock `mtp-sendfile` fails), an uncached session made it store a sent file twice, and its object list can be stale within a session, so every check opens a new one.

Without the script, an MTP client works too: open the watch in OpenMTP, copy `bin/wellface-release.prg` into `GARMIN/Apps` (the FR265 spells the folder `Apps`), then quit OpenMTP.

To update, run `scripts/sideload.sh` again. The watch installs a sideloaded PRG and then deletes the file, so an empty `Apps` folder does not mean the face is gone.

To remove the face, use Garmin Express on the computer (it also connects over MTP): open the watch's Connect IQ apps section, filter by watch faces and remove Wellface (user report, menu names may differ slightly). Fully quit Garmin Express afterwards, before running `scripts/sideload.sh`.
