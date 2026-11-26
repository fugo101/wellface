# Build, test and sideload

All commands run from the repo root. The scripts find the SDK that the Connect IQ SDK Manager marked as current (override with `CIQ_SDK=<sdk folder>`), and need `java` on `PATH`. Set `CIQ_DEVICE=<product id>` to build, run or test for a device other than the default `fr265`; `scripts/release.sh` builds every device in `manifest.xml`.

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
| `scripts/build-timing.sh` | `bin/wellface-timing.prg` | the release build with the timing code built in, see "Timing build" |
| `scripts/run-profile.sh [file.prg]` | `bin/wellface-profile.prg` | profile build (or the given PRG), start the simulator and load it |
| `scripts/watch-logs.sh list \| create <NAME> \| get <NAME> <file> \| delete <NAME>` | — | the watch's `GARMIN/Apps/LOGS` over USB: list, create an empty log file, copy a log back, delete one |
| `scripts/profile-sim.sh <file.prg> <dir> [run]` | `<dir>/<run>.PRF`, `.txt`, `-memory.txt` | the fixed profiling scenario in the simulator, unattended, see "Profile" |
| `scripts/timing-sim.sh <file.prg> <log> [loads]` | `<log>` | a timing build in a fixed simulator scenario, unattended, then its summary, see "Timing build" |
| `scripts/capture.sh <dir> [--compare <dir>]` | `<dir>/<scenario>.png` | simulator screenshots of fixed scenarios, compared pixel by pixel, see "Captures" |
| `scripts/release.sh <semver>` | `bin/release/v<semver>/wellface-<device>.prg`, `SHA256SUMS` | release builds for every device in `manifest.xml`, see "Release" |
| `scripts/sideload.sh [file.prg]` | `GARMIN/Apps/WELLFACE.PRG` on the watch | release build, then copy it to the watch over USB (or copy the given PRG) |
| `scripts/gen-fonts.sh` | `resources/fonts/`, `source/FontCatalog.mc` | regenerate the bitmap fonts, the icon font and the font catalog |
| `scripts/gen-contours.sh` | `resources/contours/` | regenerate the contour texture's pieces, see "Contour texture" |

Every build fails on any compiler warning. Type checking is strict, set in `monkey.jungle`.

`sideload.sh` exits 0 when exactly one full-size copy is confirmed on the watch, 1 when the copy is not confirmed and 2 when it could not run (no watch, an MTP app holding it, missing tools, failed build).

`run-tests.sh` starts the simulator hidden and in the background (`open -g -j`), so it takes no screen space and no focus; the tests still run in it. A simulator that is already running is left as it is. Set `CIQ_SIM_SHOW=1` to start it the usual way, with its window. `run-tests.sh` exits 0 when all tests pass, 1 when a test fails and 2 when the tests could not run (the build failed, or there is no `RESULTS` block because the simulator was not reachable, the app crashed or the run timed out). It ignores `monkeydo`'s exit code, which is 1 even when every test passes (SDK 9.3.0).

## Fonts

`scripts/gen-fonts.sh` runs the font generator (`tools/fontgen/generate.py`). It downloads the source fonts fresh from Google Fonts (the google/fonts repository, so it needs the network) and rewrites everything in `resources/fonts/` (BMFont `.fnt` + PNG pages, `fonts.xml`, the OFL license files) and `source/FontCatalog.mc`, the font catalog: one entry per font, the icon font included, with its resource, glyph set, glyph widths (the `.fnt` xadvances), base, cap height and letter spacing. FaceModel measures text and the renderer loads and draws fonts through the same entry, and a glyph-coverage test (`tests/GlyphCoverageTest.mc`) fails if any string the face can print uses a glyph its font lacks. It reads google/fonts at the latest commit on `main` (Q31). To rebuild exactly the fonts of an earlier commit, set `GOOGLE_FONTS_COMMIT=<sha>`; the fonts in the repo were generated from `29b4ec6df2522a8aee279414b78a07910b065874` (2026-11-13), and regenerating from it, or from `main` while upstream is unchanged, leaves `resources/fonts/` byte-identical (checked again on 2026-11-15 for the 86 px time font: `main` at `cc39c4c2c304bc368c9b7c311ea2bcc6013299fe` gives the same files; Big Shoulders last changed upstream on 2026-03-03). The time font is Big Shoulders Display ExtraBold (the variable Big Shoulders at wght 800, opsz 72) at 86 px (Q8/Q16), glyphs `0–9 :` only: the `0` rises 69 px above the baseline, every digit has a 42 px cell and the colon 21 px, so `08:42` is 189 px wide. Never edit those files by hand; change the `FONTS` list (or `ICONS`, for the icon font) in the generator and run the script again. Commit the generated files.

The first run creates a gitignored `.venv/` with Python 3.15 (override with `PYTHON=<interpreter>`) and the pinned versions in `tools/fontgen/requirements.txt`. The generator fails if a requested glyph is missing from a source font, if the time font's `0` does not rise 69 px ± 1 above the baseline (the design's digit height, measured like its `measureText('0').actualBoundingBoxAscent`, so the overshoot below the baseline is not counted), if a digit's ink does not fit its tabular cell, or if an asserted advance (`0` 42 px, `:` 21 px) differs.

## Contour texture

`scripts/gen-contours.sh` runs the contour generator (`tools/contourgen/generate.py`, standard library only, no network; `PYTHON=<interpreter>` overrides `python3.15`, as for the fonts). It computes the final design's contour lines (its `topo`: lines l = 1…40 of 64 points, r = 13·l·f(t) around (132, 318)), keeps the lines that reach the background disc (1–30), and cuts every segment so it stays at least half a pen inside r 194 and at least a pen width (plus 0.75 px, so rounding to whole pixels cannot break it) outside every well: the time band, the round fields and the bottom field measured at their rims, and the battery well (the arc band r 174–186 from −36° to +36° with its round caps). It reads the geometry from the integer constants in `source/Layout.mc` and writes `resources/contours/contours.json` (the pieces as packed numbers, format in `source/Contours.mc`) and `contours.xml` (its `jsonData` resource). It stops with an error if a rounded segment breaks a margin. Run it after any change to the wells, the rims or the disc and commit the output: `tests/ContourTest.mc` checks every segment against the static layer's wells and fails until the table is regenerated. Two runs give the same files (checked with Python 3.15.2 on macOS; another platform's `sin`/`cos` could move an endpoint by one pixel, and the test would still hold it to the margins).

## Run in the simulator

`scripts/run-sim.sh` builds, starts the simulator and loads the face. It stays attached and prints the face's log; press Ctrl+C to stop it.

To try a long press, hold the left mouse button on a field for about a second. The simulator shows a plain launch view (for example "Body Battery launched") instead of a Garmin page; File → Kill App, then `scripts/run-sim.sh` again, brings the face back.

To check Always On, choose Settings → Display Mode → Always-On in the simulator (High Power switches back), then File → View Screen Heat Map. The heat map window shows the current luminance usage, and its 24-Hour Simulation reports the peak luminance usage and whether burn-in was detected (simulator of SDK 9.3.0).

## Profile

`scripts/build-profile.sh` builds the release build with profiling support (`-k`). `scripts/run-profile.sh [file.prg]` builds it (or takes the given PRG), starts the simulator and loads it; the simulator then opens its profiler (File → View Profiler) and starts it by itself (SDK 9.3.0).

The measurement scenario is fixed (described below), so numbers stay comparable from one change to the next. `scripts/profile-sim.sh <file.prg> <out dir> [run name]` runs it unattended in about four minutes: it restarts the simulator, loads the PRG, sets Settings → Display Mode → High Power and Simulation → Activity Data → Data Source: Data Simulation (heart rate then changes about every second), waits 30 s, switches to Settings → Display Mode → Always-On, waits 3 minutes, reads File → View Memory (current and peak memory), stops the profiler and reads its log. It drives the menus by UI scripting, so it needs macOS and the Accessibility permission for the terminal; leave the mouse and keyboard alone while it runs. Run it twice per build: the spread between the two runs is the profiler's noise.

It writes `<run>.PRF` (the profiler's log), `<run>.txt` and `<run>-memory.txt`. `tools/profile/prf.py <file.PRF> <file.prg.debug.xml> [function ...]` turns a log into the profiler's table (calls, Total, Actual and Average time in µs per function) and also splits `WellfaceView.onUpdate` into high-power and Always On updates. The numbers to compare are the Average Time of the high-power and the Always On update, `FaceModel.compute`, `FaceModel.computeAod` and `DataReader.readComplication` (mostly the heart-rate read: it runs every second, Body Battery and stress once a minute), and the peak memory.

The script reads the log itself because the profiler window can show nothing: with SDK 9.3.0 the simulator wrote the log under the name of an earlier build of the same app (`WELLFACE-TEST.PRF`) and then looked for that build's debug file, failing with "Unable to load debug.xml data for this app". The `.PRF` format is not documented; `prf.py` describes what was read from it.

On the watch (verified on the FR265, 2026-11-14): create the log files first with `scripts/watch-logs.sh create WELLFACE.PRF` (and `WELLFACE.TXT` for `System.println` output), sideload a profile build with `scripts/sideload.sh bin/wellface-profile.prg`, unplug and wear it, plug in again and copy the log back with `scripts/watch-logs.sh get WELLFACE.PRF <local file>`. `prf.py` reads it with the build's `.prg.debug.xml`. Two differences from the simulator's log: the watch starts a new log each time the face starts (seen after a return from a widget; a return from the widget loop alone does not restart the face, see "Timing build"), so it holds only the last run; and its clock advances only while the face's code runs, so times are execution time, not wall time. Whether the files must exist beforehand was not tested (they did). Sideload the normal build afterwards and delete the log files (`scripts/watch-logs.sh delete <NAME>`).

## Timing build

The watch's profiler counts only the face's own code, not native drawing, and the simulator's profiler gives only averages, so update times on the watch come from the timing build. `scripts/build-timing.sh` builds `bin/wellface-timing.prg`: the release build (`-r`) plus `timing.jungle`, which swaps the `(:timing)` module in `source/Timing.mc` in for its `(:notiming)` no-op stand-in. Every other build (`monkey.jungle`, the capture face) leaves the timing code out; only the no-op calls remain.

With `System.getTimer()` (milliseconds) it records:

| Kind | What |
|---|---|
| `update` | a high-power update (`WellfaceView.onUpdate` after the display-mode check); the first after a start, a show or a wake is filed under the next three kinds instead |
| `first` / `firstAod` | the first update after a face start, in high power or AOD; it includes the static layer paint |
| `show` | the first high-power update after the view was hidden and shown again without a restart; the static buffer is kept |
| `wake` | the first high-power update after AOD (or a screen off, which comes after AOD) |
| `aod` | an AOD update |
| `asleep` | a high-power update while the face sleeps: after `onEnterSleep` the FR265 can keep the screen lit in high power (a tap keeps it lit), with an update once a minute and no seconds |
| `frame` / `aodFrame` | `FaceModel.update` / `FaceModel.updateAod` on their own; a change of the second alone (the seconds' fast path) is not timed as a `frame` |
| `static` | the static layer paint (`Renderer.paintStatic`), into its buffer or straight on the screen |
| `minute` | a rebuild of the minute layer (the static buffer copied into the minute buffer, then every part that changes at most once a minute) |
| `contours` / `contoursBuffer` | the contour texture alone, inside a `static` reading: on the screen (the frame drawn straight there after a face start or a new face config) or into the static buffer |

An update's time covers the face's own code in `onUpdate`, the `frame`, `static` and `minute` readings inside it included; whatever the system does after `onUpdate` returns (copying to the screen) is outside it. `System.getTimer()` counts whole milliseconds, so compare medians over many updates, and note that a difference under about 1 ms cannot be seen.

On the FR265 (2026-11-15, two wears) a return from a widget takes one of two paths. Scrolling the widget loop and going back to the face only hides the view (`onHide`, then `onShow`): the face keeps running with its static buffer, and the next update is a `show`. Opening a widget in full stops the face (`AppBase.onStop`): going back starts it again, and the next update is a `first`, with the static layer painted again. A wear for the cost limits needs both.

The readings stay in memory and are printed (`System.println`) only when the face enters AOD (`onEnterSleep`), when the view is hidden (`onHide`) or the app stops (`onStop`), and at the end of an update that leaves the buffer nearly full (240 readings), so no print falls inside a timed part. Each flush prints `timing flush <reason> <count>`, then the readings, 20 to a line, each as a one-letter code and its milliseconds (`timing F198 s92 u19 f4 u23`; codes in `tools/timing/summary.py`). The watch moves `WELLFACE.TXT` to `WELLFACE.BAK` once it passes about 5 kB and starts a new one (seen on the FR265, 2026-11-15); a later move replaces the `.BAK`, so a log that grows past about 10 kB loses its start. The short format keeps a 10-minute wear well under 5 kB. `tools/timing/summary.py <log> [<log> ...]` prints per kind the count, median, 10th and 90th percentile, minimum, maximum and mean, for each log and pooled, and warns when readings are missing (a flush cut short, or readings before the first header).

On the watch:

1. Fully quit Garmin Express and OpenMTP, connect the watch.
2. `scripts/watch-logs.sh create WELLFACE.TXT`: the watch writes `System.println` output only into an existing file named after the PRG.
3. `scripts/build-timing.sh`, then `scripts/sideload.sh bin/wellface-timing.prg`.
4. Unplug, make sure Wellface is the active face, and wear it for 5–10 minutes:
   - at least 12 wakes (raise the wrist or press a button), each kept awake 10–15 s by tapping the screen now and then (short taps; a long press on a field opens its page), then left to fall back to Always On. This gives the 100 or more per-second updates a wear needs; wakes of a few seconds gave 57 in 12 wakes;
   - at least 3 returns from the widget loop (Up or Down or a swipe from the face, scroll, then back to the face) and at least 3 from a widget opened in full (select a widget in the loop, then Back to the face). Button names may differ slightly.
5. Plug in again, list the logs with `scripts/watch-logs.sh list` and copy them back: `scripts/watch-logs.sh get WELLFACE.TXT <dir>/wearN.txt`, and if a `WELLFACE.BAK` is listed, `scripts/watch-logs.sh get WELLFACE.BAK <dir>/wearN.bak`; then `cat <dir>/wearN.bak <dir>/wearN.txt > <dir>/wearN-all.txt` (the `.BAK` first).
6. Read it: `python3 -I tools/timing/summary.py <dir>/wearN-all.txt`. There must be no warning, and the flushes must add up to the wear: about one `sleep` per wake, one `hide` per return from the widget loop and one `stop` per widget opened in full. High-power updates come in two groups about 4 ms apart on the watch, with and without a recomputed frame (heart rate changed or not; a second that only moves the seconds counts as without), so the plain median jumps with the mix; compare the `update+frame` and `update-frame` medians (or the mean) between builds. `update+minute` lists the updates that rebuilt the minute layer (they are in one of the two groups as well), and `perWake` the summed high-power update time of each time awake (a wake and the updates after it, up to the sleep flush that ends them; it grows with the time awake). Compare against a wear of the previous build taken the same way.
7. Repeat steps 2–6 for a second wear (first `scripts/watch-logs.sh delete WELLFACE.TXT` and, if present, `delete WELLFACE.BAK`, then create `WELLFACE.TXT` again, so each wear has its own log); the difference between the two wears is the noise.
8. Afterwards: delete `WELLFACE.TXT` and `WELLFACE.BAK` the same way and run `scripts/sideload.sh` to put the normal release build back.

In the simulator, `scripts/timing-sim.sh bin/wellface-timing.prg <log file> [loads]` runs a fixed scenario unattended and prints the summary: it restarts the simulator and loads the PRG 5 times (by default), each time High Power with Data Simulation (heart rate changing about every second) for about 21 s, Always-On 5 s, High Power 5 s, Always-On 4 s. Like `profile-sim.sh` it drives the menus by UI scripting (macOS, the Accessibility permission, hands off for about 40 s per load); run it twice per build for the noise. By hand, `scripts/run-profile.sh bin/wellface-timing.prg` loads the PRG and prints the same lines when the display mode is switched to Always-On or the app is killed (File → Kill App). Simulator times are for information only; compare watch timings only with watch timings.

## Captures

`scripts/capture.sh <dir>` takes simulator screenshots of the face in fixed scenarios, named after the final design's frames (their numbers in the design's frame list) and fed each frame's data, so a capture can be compared by eye with the frame: `frame1` (normal: 08:42:37, T5 12/11, stress 27, Body Battery 56, heart rate 62, 1.147 / 3.110 steps, battery 78%), `frame1sec00` (frame 1 at second 00, the widest seconds), `frame2` (level 1 warnings), `frame3` (level 2 warnings), `frame5` (active: heart rate 142 in zone 3, 17:30), `frame7` (step goal reached, 3.512), `frame11` (missing data), `frame11b` (1.147 / 10.000 steps, too long for the icon) and `frame12` (Always On), plus four cases the design has no frame for: `goalReached` (exactly the goal), `warning` (level 2 everywhere, battery 5%, heart rate in zone 5), `longSteps` (12.345 of 15.000) and `steps100000`. Each scenario goes through the renderer's per-second path, as on the watch: a frame with the second and heart rate before the scenario's, repainted until the minute layer is built from it, then a seconds-only update and a heart-rate-only update to the scenario's data. `CAPTURE_FULL_REPAINT=1` forces the renderer's full repaint instead (its fallback when the graphics pool has no room; it logs `wellface: no room for the minute layer (forced), full repaint`), so the two paths can be compared within one build. The per-second path draws the minute content into a buffer, and the simulator's anti-aliasing in a buffer differs slightly from drawing on the screen: up to 9 of 255 in a channel along the edges of lines, arcs and text. It builds the capture face (`tools/capture/`: the face's own FaceModel, Renderer, fonts and resources, fed a fixed snapshot instead of sensors) once per scenario, loads it and captures the simulator window. With `--compare <dir>` it then compares each capture with the one of the same name in that folder, pixel by pixel, in every channel (the window's title bar and status bar left out). The first capture of a run can differ around the face when the simulator window was not yet focused; compare inside the screen disc before treating that as a change. It exits 0 when everything was captured (and, with `--compare`, every capture is identical), 1 when a capture differs or is missing, and 2 when it could not run (build failed, no simulator, missing permission). Two runs of the same build give identical captures. The face is captured in the mint theme, whatever theme the built-in face config names, so captures stay comparable when the face's theme changes; `CAPTURE_THEME=<theme name> scripts/capture.sh <dir>` (for example `volt`) captures another theme; the name is lowercase, as in `source/Theme.mc`, and an unknown one stops the script (exit 2) instead of silently capturing mint.

Captures are machine-specific (display scale, simulator version), so compare only captures taken on the same Mac. Keep them in the gitignored `captures/` folder. It needs macOS and the Screen Recording permission for the terminal, and `.venv` (created by `scripts/gen-fonts.sh`) for `--compare`.

## Sideload to the watch

One-time setup: install libmtp (on macOS: `brew install libmtp`). A C compiler is needed too (on macOS: the Xcode Command Line Tools). `sideload.sh` finds libmtp through `pkg-config` or Homebrew, so no path is configured.

1. Fully quit Garmin Express and any MTP client (OpenMTP): only one program can hold the watch's USB connection.
2. Connect the watch with the cable and run `scripts/sideload.sh`. It builds the release PRG, compiles the MTP helper `bin/mtp-push` from `tools/sideload/mtp_push.c` the first time (or after the source changes), removes any `WELLFACE.PRG` still waiting in `GARMIN/Apps`, sends the new one, and checks in a fresh MTP session that exactly one full-size copy is there.
3. Unplug the watch and choose Wellface from the watch-face list (menu names may differ slightly).

The helper works around three FR265 MTP quirks: the watch rejects storage id 0 (so the stock `mtp-sendfile` fails), an uncached session made it store a sent file twice, and its object list can be stale within a session, so every check opens a new one.

Without the script, an MTP client works too: open the watch in OpenMTP, copy `bin/wellface-release.prg` into `GARMIN/Apps` (the FR265 spells the folder `Apps`), then quit OpenMTP.

To update, run `scripts/sideload.sh` again. The watch installs a sideloaded PRG and then deletes the file, so an empty `Apps` folder does not mean the face is gone.

To remove the face, use Garmin Express on the computer (it also connects over MTP): open the watch's Connect IQ apps section, filter by watch faces and remove Wellface (menu names may differ slightly). Fully quit Garmin Express afterwards, before running `scripts/sideload.sh`.

## Release

`scripts/release.sh <semver>` (for example `scripts/release.sh 0.1.0`) builds every product listed in `manifest.xml` with the release flags of `scripts/build-release.sh`, signed with your developer key (`CIQ_DEV_KEY`), into `bin/release/v<semver>/wellface-<device>.prg`, and prints and writes the SHA-256 sums (`SHA256SUMS`). It refuses a version that is not SemVer or an output folder that already exists, and it publishes nothing. Releases are built on the maintainer's machine with the real developer key; the key never goes to CI (Q50).

To publish, tag the commit on `main` and create the GitHub Release. The notes carry the install and uninstall steps from "Sideload to the watch":

```sh
scripts/release.sh 0.1.0
gh release create v0.1.0 bin/release/v0.1.0/* --title v0.1.0 --notes-file <notes file>
```

The reasoning behind the release format is in `docs/research/ci-and-distribution.md`, "Distribution through GitHub Releases".

## CI

Workflows are in `.github/workflows/`. Facts and open questions behind them: `docs/research/ci-and-distribution.md`.

| Workflow | Runs | Required | Needs |
|---|---|---|---|
| `pr-title.yml`, job `Conventional PR title` | pull requests | yes | nothing |
| `lint.yml`, job `Lint` | push to `main`, pull requests | yes | nothing: shellcheck on `scripts/`, ruff on the Python in `tools/`, actionlint on the workflows |
| `build.yml`, job `Monkey C build (compile only)` | push to `main`, same-repo pull requests | no | the secrets `GARMIN_USERNAME` and `GARMIN_PASSWORD` of a dedicated Garmin account without 2FA |

The build job compiles the face for every device in `manifest.xml` in an `ubuntu:22.04` container and does not run the tests. It downloads the pinned SDK zip (SHA-256 checked) and the device files fresh on every run and caches nothing from Garmin, signs with a throwaway key made in the job, and does not run on pull requests from forks (the job is skipped); on other runs it passes with a notice, running no other step, when the secrets are absent. The unit tests do not run in CI yet (a later experiment); `scripts/run-tests.sh` on your machine is the authority. To run the lint checks locally: `shellcheck scripts/*.sh`, `ruff check tools` and `actionlint`.
