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

Every build fails on any compiler warning. Type checking is strict, set once in `monkey.jungle`.

`run-tests.sh` exits 0 when all tests pass, 1 when a test fails and 2 when the tests could not run (the build failed, or there is no `RESULTS` block because the simulator was not reachable, the app crashed or the run timed out). It ignores `monkeydo`'s exit code, which is 1 even when every test passes (SDK 9.3.0).

## Run in the simulator

`scripts/run-sim.sh` builds, starts the simulator and loads the face. It stays attached and prints the face's log; press Ctrl+C to stop it.

To check Always On, turn on low-power mode in the simulator's settings menu, and use File → View Screen Heat Map (menu names may differ slightly).

## Sideload to the watch

1. Run `scripts/build-release.sh`.
2. Fully quit Garmin Express, connect the watch with the cable and open it with an MTP client (on macOS: OpenMTP).
3. Copy `bin/wellface-release.prg` into `GARMIN/APPS` on the watch (the FR265 spells the folder `Apps`). Keep the MTP client closed afterwards: while it runs, it holds the watch's USB connection, so no other tool can reach it.
4. Unplug the watch and choose Wellface from the watch-face list (menu names may differ slightly).

To update, copy the new `.prg` over the old one. To remove the face, delete it from `GARMIN/APPS`.

While the MVP is in progress, Always On shows a black screen until the AOD ticket lands.
