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
| `scripts/build-release.sh` | `bin/wellface-release.prg` | sideload to the watch (`-r --build-stats 0`) |
| `scripts/gen-fonts.sh` | `resources/fonts/`, `source/GlyphWidths.mc` | regenerate the bitmap fonts and glyph-width tables |
| `scripts/build-spike.sh` | `bin/wfspike.prg` | data spike (ticket 02), a separate debug-only face |
| `scripts/run-spike.sh` | `bin/wfspike.prg` | data spike, start the simulator and load it |

Every build fails on any compiler warning. Type checking is strict, set in each jungle (`monkey.jungle`, `spikes/data/monkey.jungle`).

`run-tests.sh` exits 0 when all tests pass, 1 when a test fails and 2 when the tests could not run (the build failed, or there is no `RESULTS` block because the simulator was not reachable, the app crashed or the run timed out). It ignores `monkeydo`'s exit code, which is 1 even when every test passes (SDK 9.3.0).

## Fonts

`scripts/gen-fonts.sh` runs the font generator (`tools/fontgen/generate.py`). It downloads the source fonts fresh from Google Fonts (the google/fonts repository, so it needs the network) and rewrites everything in `resources/fonts/` (BMFont `.fnt` + PNG pages, `fonts.xml`, the OFL license files) and `source/GlyphWidths.mc`. Never edit those files by hand; change the `FONTS` list in the generator and run the script again. Commit the generated files.

The first run creates a gitignored `.venv/` with Python 3.15 (override with `PYTHON=<interpreter>`) and the pinned versions in `tools/fontgen/requirements.txt`. The generator fails if a requested glyph is missing from a source font, or if the time font's `0` is not 46 px ± 1 tall.

## Run in the simulator

`scripts/run-sim.sh` builds, starts the simulator and loads the face. It stays attached and prints the face's log; press Ctrl+C to stop it.

To check Always On, turn on low-power mode in the simulator's settings menu, and use File → View Screen Heat Map (menu names may differ slightly).

## Data spike

`spikes/data/` is a separate debug-only face (own jungle, manifest and app id) that shows raw sensor values as plain text: Body Battery, stress and heart rate polled from complications, steps and the step goal, the `HR_ZONE_SPORT_GENERIC` zones and the `FORMAT_MEDIUM` weekday with its code points. Each value shows the clock time it last changed. Nothing in it is part of `monkey.jungle`, so it never reaches the release build.

It shows up on the watch as its own face, "Wellface data spike", next to Wellface. Sideload `bin/wfspike.prg` like the release PRG below. To also keep a log of every change on the watch, create an empty file `GARMIN/APPS/LOGS/WFSPIKE.TXT` before unplugging (Garmin's debugging guide: the log file must exist and match the PRG name). In the simulator, `run-spike.sh` does not print the log (seen with SDK 9.3.0).

## Sideload to the watch

1. Run `scripts/build-release.sh`.
2. Fully quit Garmin Express, connect the watch with the cable and open it with an MTP client (on macOS: OpenMTP).
3. Copy `bin/wellface-release.prg` into `GARMIN/APPS` on the watch (the FR265 spells the folder `Apps`). Keep the MTP client closed afterwards: while it runs, it holds the watch's USB connection, so no other tool can reach it.
4. Unplug the watch and choose Wellface from the watch-face list (menu names may differ slightly).

To update, copy the new `.prg` into `GARMIN/Apps` again. The watch installs a sideloaded PRG and then deletes the file, so an empty `Apps` folder does not mean the face is gone.

To remove the face, use Garmin Express on the computer (it also connects over MTP): open the watch's Connect IQ apps section, filter by watch faces and remove Wellface (user report, menu names may differ slightly). Fully quit Garmin Express afterwards, before copying a PRG with another MTP tool.

While the MVP is in progress, Always On shows a black screen until the AOD ticket lands.
