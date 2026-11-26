# Wellface

A custom Connect IQ watch face, written in Monkey C, for round AMOLED Garmin watches. The Forerunner 265 is the only maintained device; others are community ports (see Device support). Open source on GitHub (`fugo101/wellface`, Apache-2.0).

The name: "well" is both a well (every element sits inside a black well) and wellness. There are several themes (Q42), so keep names, code and docs free of a fixed color. Colors go through a palette/theme.

## Language and personal data
- Everything in the repo is English: code, comments, docs, commit messages, issues and PRs. Exceptions (Q51): data the watch returns (Vietnamese weekday forms) and the Claude Design export in `design/claude-design/`, kept as exported.
- The repo is public. Use placeholders and made-up values for names, emails, machine paths (`/Users/...`), the developer key's location and health numbers (steps, heart rate, goals).
- The Garmin SDK, device files and Garmin fonts stay out of the repo (the Connect IQ developer agreement does not allow redistributing them).

## Docs
Read `docs/decisions.md` before coding. Reach for the others when their topic comes up.

| Doc | What it holds |
|---|---|
| `docs/decisions.md` | Every agreed decision (Q1–Q53). Only the maintainer changes one, in the same PR as the change that needs it; ask in the issue first |
| `docs/spec.md` | The face as built: layout, fields, themes, refresh plan, Always On, testing |
| `GLOSSARY.md` | The project vocabulary: fields are named by position, the metric decides how a field is drawn |
| `docs/research/connect-iq-platform.md` | Verified Connect IQ platform facts for the FR265, with sources and open questions |
| `docs/research/ci-and-distribution.md` | CI, licensing, multi-device and release findings |
| `docs/build.md` | Build, test, simulator, profiling, release, CI and sideload commands (`scripts/`) |
| `docs/design-sync.md` | Where the built face differs from the final design. Add a row whenever a change departs from the design |
| `docs/design-brief.md` | The brief given to Claude Design (historical) |
| `CONTRIBUTING.md` | Issue-first rules, device support, PR flow |
| `CODING_STANDARDS.md` | The rules reviewers hold changes to |

### The design file
`design/claude-design/FR265 Watch Face.dc.html` is the final design. Coordinates, colors, fonts and the spec table live in its `buildG` function and `spec` array. Read the source; rendering it is unnecessary. `design/claude-design/` is the extracted Claude Design handoff bundle. When Claude Design exports a new bundle, extract it on macOS with `ditto -x -k` (`unzip` fails on non-ASCII file names inside) and copy `garmin-forerunner-265-watch-face/project/*` over this folder. The `.zip` is gitignored. `support.js` is Claude Design's generated runtime, not the project's work: leave it as exported.

## Device and platform (verified)
- FR265: Connect IQ API **5.2**, round 416×416 AMOLED (FR265S is 360×360, not supported yet). Store: deviceTypeId 272, partNumber `006-B4257-00`.
- Complications (API 4.2+) available: HR, stress, Body Battery, Pulse Ox, respiration, recovery time, steps, intensity minutes, weather. **No sleep score** (needs API 6.0.2), HRV status or Training Readiness.
- Long-press on a field of a CIQ face: `onPress` (API 4.2) + `Complications.exitTo`.
- AMOLED in AOD/low-power mode: since the Venu 2, the SDK docs give the rule as **less than 10% of the screen's luminance** (the older "10% of pixels, no pixel lit > 3 minutes" rule was for the original Venu). Breaking the rule makes the watch turn the screen off. Which rule the FR265 firmware enforces is not documented; the simulator heat map decides (File → View Screen Heat Map, low-power mode on). The face shifts the AOD time and date up to 4 px each minute, as Garmin's guidelines recommend, to limit physical burn-in.
- A sideloaded face has **no Settings page in the phone app**. All configuration is hard-coded in the built-in face config (or an on-watch menu if ever needed).
- The face reads goals (`stepGoal`, the weekly intensity-minutes goal) from the watch; the wearer's goal is never entered by hand. Step goals can be in Garmin's auto mode, which changes daily.

## Device support
Community project: the maintainer guarantees only the Forerunner 265. Another device is added by its owner, issue first, with simulator screenshots (Always On heat map included) and an on-watch confirmation; the porter is listed in `.github/CODEOWNERS` for that device's files. A port must not change a single FR265 pixel (the FR265 golden tests stay unchanged). Details: `CONTRIBUTING.md` › Device support, `docs/decisions.md` Q47.

## Development setup
- Requirements: the latest stable JDK (the SDK needs 11 or higher; 17, 25 and 27 tested; use the arm64 build on Apple Silicon), the Connect IQ SDK and the FR265 device files, both downloaded through the Connect IQ SDK Manager (needs a Garmin account). The scripts are developed and verified on macOS.
- Developer key: an RSA 4096 private key in DER format, kept **outside the repo** and pointed to by `CIQ_DEV_KEY`. Every build is signed with it (`monkeyc -y <key>`). Never commit, copy or print the key.
- Editor: VS Code/Cursor with the official extension `garmin.monkey-c` (not on Open VSX, so Cursor needs the .vsix). Agents build with the SDK CLI (`scripts/`).
- Installing on a watch: `scripts/sideload.sh` builds the release PRG and copies it to `GARMIN/Apps` over MTP with libmtp (see `docs/build.md`). Garmin Express and OpenMTP must be fully quit; OpenMTP is the manual fallback.

## Testing
- **A single test seam: `FaceModel`**, pure logic. Input: a face config (the theme and the metric in each field, resolved by `FaceModel.resolve`), a snapshot (clock, battery, HR zones, each metric's value and goal), the change kinds since the previous frame, and the mode (high power or AOD). Output: what to draw (the frame with the seconds and the lit bezel ticks, the AOD frame with its burn-in offset, the static layer with the edge mask, the unlit bezel ticks and the contour texture's color: strings, colors, arcs, lines, text layout), the long-press target at a touch point, the metrics each field accepts, the read plan (which metrics the reader reads, and how often), the frame parts each change kind invalidates, which parts change every second or at most once a minute, and whether a set of change kinds makes the minute layer stale (`minuteLayerChanged`). A snapshot without a second (the face asleep with the screen still lit) has no seconds. `update`/`updateAod` recompute only those parts (a change of the second alone only sets the seconds); their result must equal a full `compute`/`computeAod`. The contour pieces are a generated table, not FaceModel output; `tests/ContourTest.mc` checks every piece against the static layer's wells. Tested with Monkey C unit tests (`(:test)`) run in the simulator; golden values (`tests/GoldenValues.mc`) pin the default face in the mint theme, so tests hold whichever theme the built-in face config names.
- Keep sensor reading and drawing thin; check them by eye in the simulator (against the design) and with the AOD heat map.
- Before a PR: `scripts/build-release.sh` builds with zero warnings, `scripts/run-tests.sh` passes. Visual changes: `scripts/capture.sh` before and after (`docs/build.md`, "Captures"). Generated files (fonts, font catalog, contours) come from `scripts/gen-fonts.sh` and `scripts/gen-contours.sh`, never from hand edits.

## Performance
Lesson from an earlier face: it lagged when returning from menus because it redrew everything every second (~25 drawText calls with custom fonts + a gradient bitmap). Therefore:
- Seconds only while the face gets per-second updates (high power, between `onExitSleep` and `onEnterSleep`); the FR265 stops them about 10 s after a wake even when a tap keeps the screen lit, and the seconds are hidden then rather than frozen. A change of the second alone redraws only the seconds and recomputes nothing else (Q41, Q44). Data updates once a minute, except heart rate, which is re-read every second while the screen is awake.
- Static parts (background, contour texture, wells, tracks, unlit bezel ticks) are drawn once into a buffer. A second buffer, the minute layer, holds those plus everything that changes at most once a minute; each second it is copied and only the seconds and the field showing heart rate are drawn over it (Q44). Drawing into a buffer is about 2.5 times slower than on the screen on the FR265, so a frame whose minute layer is stale (a wake, a new minute, a face start) is drawn straight on the screen and the buffers follow on the next updates. The contour texture is cut in advance at build time (`scripts/gen-contours.sh`) so it never covers a well, and is drawn with the static layer: into its buffer, and once on the screen with the first frame after a face start; a full repaint without a static buffer leaves it out (Q43).
- Use only the bitmap fonts needed, each containing only the glyphs in use.
- A render-path change comes with timings before and after (`docs/build.md`, "Timing build"); none may get worse (Q44).

## Workflow
- Default branch `main`. Work on a branch; every change goes through a PR, squash-merged, with a Conventional Commits title (`type(scope): summary`). CI and the PR template: `CONTRIBUTING.md`, `docs/build.md` › CI.
- Open an issue before a port, a new metric, field kind or theme, a layout or color change, or a change to `FaceModel`, the render path or the refresh plan.

## Agent skills

### Issue tracker

Issues live in GitHub Issues on `fugo101/wellface` (public), via the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

Default labels: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`, plus `device: <id>` labels, applied as GitHub labels. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `GLOSSARY.md` + `docs/adr/` at the repo root; existing decisions live in `docs/decisions.md`. See `docs/agents/domain.md`.
