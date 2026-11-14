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
| `scripts/watch-logs.sh list \| create <NAME> \| get <NAME> <file> \| delete <NAME>` | — | the watch's `GARMIN/Apps/LOGS` over USB: list, create an empty log file, copy a log back, delete one |
| `scripts/profile-sim.sh <file.prg> <dir> [run]` | `<dir>/<run>.PRF`, `.txt`, `-memory.txt` | the fixed profiling scenario in the simulator, unattended, see "Profile" |
| `scripts/capture.sh <dir> [--compare <dir>]` | `<dir>/<scenario>.png` | simulator screenshots of fixed scenarios, compared pixel by pixel, see "Captures" |
| `scripts/sideload.sh [file.prg]` | `GARMIN/Apps/WELLFACE.PRG` on the watch | release build, then copy it to the watch over USB (or copy the given PRG) |
| `scripts/gen-fonts.sh` | `resources/fonts/`, `source/FontCatalog.mc` | regenerate the bitmap fonts, the icon font and the font catalog |
| `scripts/build-spike.sh` | `bin/wfspike.prg` | data spike (ticket 02), a separate debug-only face |
| `scripts/run-spike.sh` | `bin/wfspike.prg` | data spike, start the simulator and load it |

Every build fails on any compiler warning. Type checking is strict, set in each jungle (`monkey.jungle`, `spikes/data/monkey.jungle`).

`sideload.sh` exits 0 when exactly one full-size copy is confirmed on the watch, 1 when the copy is not confirmed and 2 when it could not run (no watch, an MTP app holding it, missing tools, failed build).

`run-tests.sh` starts the simulator hidden and in the background (`open -g -j`), so it takes no screen space and no focus; the tests still run in it. A simulator that is already running is left as it is. Set `CIQ_SIM_SHOW=1` to start it the usual way, with its window. `run-tests.sh` exits 0 when all tests pass, 1 when a test fails and 2 when the tests could not run (the build failed, or there is no `RESULTS` block because the simulator was not reachable, the app crashed or the run timed out). It ignores `monkeydo`'s exit code, which is 1 even when every test passes (SDK 9.3.0).

## Fonts

`scripts/gen-fonts.sh` runs the font generator (`tools/fontgen/generate.py`). It downloads the source fonts fresh from Google Fonts (the google/fonts repository, so it needs the network) and rewrites everything in `resources/fonts/` (BMFont `.fnt` + PNG pages, `fonts.xml`, the OFL license files) and `source/FontCatalog.mc`, the font catalog: one entry per font, the icon font included, with its resource, glyph set, glyph widths (the `.fnt` xadvances), base, cap height and letter spacing. FaceModel measures text and the renderer loads and draws fonts through the same entry, and a glyph-coverage test (`tests/GlyphCoverageTest.mc`) fails if any string the face can print uses a glyph its font lacks. It reads google/fonts at the latest commit on `main` (Q31). To rebuild exactly the fonts of an earlier commit, set `GOOGLE_FONTS_COMMIT=<sha>`; the fonts in the repo were generated from `29b4ec6df2522a8aee279414b78a07910b065874` (2026-11-13), and regenerating from it, or from `main` while upstream is unchanged, leaves `resources/fonts/` byte-identical. Never edit those files by hand; change the `FONTS` list (or `ICONS`, for the icon font) in the generator and run the script again. Commit the generated files.

The first run creates a gitignored `.venv/` with Python 3.15 (override with `PYTHON=<interpreter>`) and the pinned versions in `tools/fontgen/requirements.txt`. The generator fails if a requested glyph is missing from a source font, if the time font's `0` is not 63 px ± 1 tall, if a digit's ink does not fit its tabular cell, or if an asserted advance (`0` 38 px, `:` 19 px) differs.

## Run in the simulator

`scripts/run-sim.sh` builds, starts the simulator and loads the face. It stays attached and prints the face's log; press Ctrl+C to stop it.

To try a long press, hold the left mouse button on a field for about a second. The simulator shows a plain launch view (for example "Body Battery launched") instead of a Garmin page; File → Kill App, then `scripts/run-sim.sh` again, brings the face back.

To check Always On, choose Settings → Display Mode → Always-On in the simulator (High Power switches back), then File → View Screen Heat Map. The heat map window shows the current luminance usage, and its 24-Hour Simulation reports the peak luminance usage and whether burn-in was detected (simulator of SDK 9.3.0).

## Profile

`scripts/build-profile.sh` builds the release build with profiling support (`-k`). `scripts/run-profile.sh [file.prg]` builds it (or takes the given PRG), starts the simulator and loads it; the simulator then opens its profiler (File → View Profiler) and starts it by itself (SDK 9.3.0).

The measurement scenario is fixed (`.scratch/settings-ready/spec.md`, refresh plan), so numbers stay comparable from one change to the next. `scripts/profile-sim.sh <file.prg> <out dir> [run name]` runs it unattended in about four minutes: it restarts the simulator, loads the PRG, sets Settings → Display Mode → High Power and Simulation → Activity Data → Data Source: Data Simulation (heart rate then changes about every second), waits 30 s, switches to Settings → Display Mode → Always-On, waits 3 minutes, reads File → View Memory (current and peak memory), stops the profiler and reads its log. It drives the menus by UI scripting, so it needs macOS and the Accessibility permission for the terminal; leave the mouse and keyboard alone while it runs. Run it twice per build: the spread between the two runs is the profiler's noise.

It writes `<run>.PRF` (the profiler's log), `<run>.txt` and `<run>-memory.txt`. `tools/profile/prf.py <file.PRF> <file.prg.debug.xml> [function ...]` turns a log into the profiler's table (calls, Total, Actual and Average time in µs per function) and also splits `WellfaceView.onUpdate` into high-power and Always On updates. The numbers to compare are the Average Time of the high-power and the Always On update, `FaceModel.compute`, `FaceModel.computeAod` and `DataReader.readComplication` (mostly the heart-rate read: it runs every second, Body Battery and stress once a minute), and the peak memory.

The script reads the log itself because the profiler window can show nothing: with SDK 9.3.0 the simulator wrote the log under the name of an earlier build of the same app (`WELLFACE-TEST.PRF`) and then looked for that build's debug file, failing with "Unable to load debug.xml data for this app". The `.PRF` format is not documented; `prf.py` describes what was read from it.

On the watch (verified on the FR265, 2026-11-14): create the log files first with `scripts/watch-logs.sh create WELLFACE.PRF` (and `WELLFACE.TXT` for `System.println` output), sideload a profile build with `scripts/sideload.sh bin/wellface-profile.prg`, unplug and wear it, plug in again and copy the log back with `scripts/watch-logs.sh get WELLFACE.PRF <local file>`. `prf.py` reads it with the build's `.prg.debug.xml`. Two differences from the simulator's log: the watch starts a new log each time the face starts (a return from a widget included), so it holds only the last run; and its clock advances only while the face's code runs, so times are execution time, not wall time. Whether the files must exist beforehand was not tested (they did). Sideload the normal build afterwards and delete the log files (`scripts/watch-logs.sh delete <NAME>`).

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
