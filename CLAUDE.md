# Wellface

A custom Connect IQ watch face for the user's Garmin Forerunner 265, for personal use only (sideloaded over USB, not published to the store). Claude writes the Monkey C code. The user designs in Claude Design and copies the files to the watch over the cable.

The name "Wellface": "well" means both a well (every element sits inside a black well) and wellness (well-being). There are several themes (Q42), so don't tie names, code or docs to a fixed color. Colors go through a palette/theme.

## Communication
- Reply to the user in Vietnamese and explain in plain language. The user works in IT but has never written Monkey C and is not strong at design. Claude owns the code.
- Write everything that lives in the repo in English: code, comments, docs, commit messages and issues.
- When a reply compares options or lists facts, put them in a short table. When there is something for the user to do, end with 1–3 concrete next steps.
- Menus on the watch, the Garmin Connect app, the Connect IQ app or Claude Design: only state paths that have been verified. Otherwise add "menu names may differ slightly".

## Docs
- `docs/decisions.md`: every agreed design decision and the MVP scope (Q1–Q45). Read it before coding. Ask the user before changing anything in it.
- `GLOSSARY.md`: the project vocabulary (fields are named by position, the metric decides how a field is drawn).
- `docs/research/connect-iq-platform.md`: verified Connect IQ platform facts for the FR265, with sources and open questions.
- `.scratch/mvp/spec.md`: the MVP spec.
- `.scratch/design-refresh/spec.md`: the design update of 2026-11-14; replaces the MVP spec where they differ.
- `.scratch/settings-ready/spec.md`: the code reshape for settings, performance and battery (face config, metric module and field kinds, refresh plan, font catalog); the default face stays pixel-identical.
- `.scratch/design-refresh-2/spec.md`: the second design update of 2026-11-14 (86 px time, seconds, bezel ticks, contour texture, 10 themes); replaces the earlier specs where they differ.
- `docs/build.md`: build, test, simulator and sideload commands (`scripts/`).
- `docs/design-brief.md`: the brief given to Claude Design.
- `docs/design-sync.md`: where the built face differs from the final design, to bring the design up to date. Add a row whenever a change departs from the design.
- `design/claude-design/FR265 Watch Face.dc.html`: **the final design**. Coordinates, colors, fonts and the spec table live in the `buildG` function and the `spec` array. Read the source; no need to render it. Older versions and screenshots were removed on 2026-11-13; they remain in git history. `design/claude-design/` is the extracted Claude Design handoff bundle. When Claude Design exports a new bundle, extract it with `ditto -x -k` (`unzip` fails on the Vietnamese file names inside), copy `garmin-forerunner-265-watch-face/project/*` over this folder. The `.zip` itself is gitignored.

## Device and platform (verified)
- FR265: Connect IQ API **5.2**, round 416×416 AMOLED (FR265S is 360×360, not supported yet). Store: deviceTypeId 272, partNumber `006-B4257-00`.
- Complications (API 4.2+) available: HR, stress, Body Battery, Pulse Ox, respiration, recovery time, steps, intensity minutes, weather. **No sleep score** (needs API 6.0.2), HRV status or Training Readiness.
- Long-press on a field of a CIQ face: `onPress` (API 4.2) + `Complications.exitTo`.
- AMOLED in AOD/low-power mode: since the Venu 2, the SDK docs give the rule as **less than 10% of the screen's luminance** (the older "10% of pixels, no pixel lit > 3 minutes" rule was for the original Venu). Breaking the rule makes the watch turn the screen off. Which rule the FR265 firmware enforces is not documented; the simulator heat map decides (File → View Screen Heat Map, low-power mode on). The face still shifts the AOD time and date up to 4 px each minute, as Garmin's guidelines recommend, to limit physical burn-in.
- A sideloaded face has **no Settings page in the phone app**. All configuration is hard-coded (or an on-watch menu if ever needed).
- The user's step goal is in **auto** mode (Garmin adjusts it daily, ~3,100 on 2026-11-12). The face reads `stepGoal` from the watch; never entered by hand. Weekly intensity-minutes goal: 150.

## Development setup
- Requirements: the latest stable JDK (the SDK needs 11 or higher; 17, 25 and 27 tested; use the arm64 build on Apple Silicon), the Connect IQ SDK and the FR265 device files, both downloaded through the Connect IQ SDK Manager (needs a Garmin account).
- Developer key: an RSA 4096 private key in DER format, kept **outside the repo**. Every build is signed with it (`monkeyc -y <key>`). If the VS Code extension generated it, its path is in the `monkeyC.developerKeyPath` user setting; otherwise ask the user. **Never commit, copy or print the key.**
- Editor: VS Code/Cursor with the official extension `garmin.monkey-c` (not on Open VSX, so Cursor needs the .vsix). Claude builds with the SDK CLI.
- Installing on the watch: `scripts/sideload.sh` builds the release PRG and copies it to `GARMIN/Apps` over MTP with libmtp (see `docs/build.md`). Garmin Express and OpenMTP must be fully quit; OpenMTP is the manual fallback.

## Testing
- **A single test seam: `FaceModel`**, pure logic. Input: a face config (the theme and the metric in each field, resolved by `FaceModel.resolve`), a snapshot (clock, battery, HR zones, each metric's value and goal), the change kinds since the previous frame, and the mode (high power or AOD). Output: what to draw (the frame with the seconds and the lit bezel ticks, the AOD frame with its burn-in offset, the static layer with the edge mask, the unlit bezel ticks and the contour texture's color: strings, colors, arcs, lines, text layout), the long-press target at a touch point, the metrics each field accepts, the read plan (which metrics the reader reads, and how often), the frame parts each change kind invalidates, which parts change every second or at most once a minute, and whether a set of change kinds makes the minute layer stale (`minuteLayerChanged`). A snapshot without a second (the face asleep with the screen still lit) has no seconds. `update`/`updateAod` recompute only those parts (a change of the second alone only sets the seconds); their result must equal a full `compute`/`computeAod`. The contour pieces are a generated table, not FaceModel output; `tests/ContourTest.mc` checks every piece against the static layer's wells. Tested with Monkey C unit tests (`(:test)`) run in the simulator; golden values (`tests/GoldenValues.mc`) pin the default face in the mint theme, so tests hold whichever theme the built-in face config names.
- Keep sensor reading and drawing thin; check them by eye in the simulator (against the design) and with the AOD heat map.

## Performance
Lesson from the previous face: Segment34 lagged when returning from menus because it redrew everything every second (~25 drawText calls with custom fonts + a gradient bitmap). Therefore:
- Seconds only while the face gets per-second updates (high power, between `onExitSleep` and `onEnterSleep`); the FR265 stops them about 10 s after a wake even when a tap keeps the screen lit, and the seconds are hidden then rather than frozen. A change of the second alone redraws only the seconds and recomputes nothing else (Q41, Q44). Data updates once a minute, except heart rate, which is re-read every second while the screen is awake.
- Static parts (background, contour texture, wells, tracks, unlit bezel ticks) are drawn once into a buffer. A second buffer, the minute layer, holds those plus everything that changes at most once a minute; each second it is copied and only the seconds and the field showing heart rate are drawn over it (Q44, ticket 08). Drawing into a buffer is about 2.5 times slower than on the screen on the FR265, so a frame whose minute layer is stale (a wake, a new minute, a face start) is drawn straight on the screen and the buffers follow on the next updates. The contour texture is cut in advance at build time (`scripts/gen-contours.sh`) so it never covers a well, and is drawn with the static layer: into its buffer, and once on the screen with the first frame after a face start; a full repaint without a static buffer leaves it out (Q43, ticket 09).
- Use only the bitmap fonts needed, each containing only the glyphs in use.

## Agent skills

### Issue tracker

Issues live as markdown files under `.scratch/<feature>/`. See `docs/agents/issue-tracker.md`.

### Triage labels

The five default labels (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`), recorded on a `Status:` line. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `GLOSSARY.md` + `docs/adr/` at the repo root; existing decisions live in `docs/decisions.md`. See `docs/agents/domain.md`.
