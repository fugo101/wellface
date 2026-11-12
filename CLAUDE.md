# Wellface

A custom Connect IQ watch face for the user's Garmin Forerunner 265, for personal use only (sideloaded over USB, not published to the store). Claude writes the Monkey C code. The user designs in Claude Design and copies the files to the watch over the cable.

The name "Wellface": "well" means both a well (every element sits inside a black well) and wellness (well-being). There will be several themes later, so don't tie names, code or docs to a fixed color. Colors go through a palette/theme.

## Communication
- Reply to the user in Vietnamese and explain in plain language. The user works in IT but has never written Monkey C and is not strong at design. Claude owns the code.
- Write everything that lives in the repo in English: code, comments, docs, commit messages and issues.
- When a reply compares options or lists facts, put them in a short table. When there is something for the user to do, end with 1–3 concrete next steps.
- Menus on the watch, the Garmin Connect app, the Connect IQ app or Claude Design: only state paths that have been verified. Otherwise add "menu names may differ slightly".

## Docs
- `docs/decisions.md`: every agreed design decision and the MVP scope (Q1–Q37). Read it before coding. Ask the user before changing anything in it.
- `GLOSSARY.md`: the project vocabulary (fields are named by position, the metric decides how a field is drawn).
- `docs/research/connect-iq-platform.md`: verified Connect IQ platform facts for the FR265, with sources and open questions.
- `.scratch/mvp/spec.md`: the MVP spec.
- `docs/build.md`: build, test, simulator and sideload commands (`scripts/`).
- `docs/design-brief.md`: the brief given to Claude Design.
- `design/claude-design/FR265 Watch Face.dc.html`: **the final design**. Coordinates, colors, fonts and the spec table live in the `buildG` function and the `spec` array. Read the source; no need to render it. `FR265 Watch Face (history).dc.html` holds older versions, for reference only. `design/claude-design/` is the extracted Claude Design handoff bundle. When Claude Design exports a new bundle, extract it with `ditto -x -k` (`unzip` fails on the Vietnamese file names inside), copy `garmin-forerunner-265-watch-face/project/*` over this folder, then rename the history file again. The `.zip` itself is gitignored.

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
- Installing on the watch: copy the `.prg` file into `GARMIN/APPS`. The watch uses MTP, so macOS needs OpenMTP, and Garmin Express must be fully quit.

## Testing
- **A single test seam: `FaceModel`**, pure logic. Input: a snapshot of the data (time, date, BB, stress, HR, HR zones, steps/goal, battery) and the mode (normal/AOD/current minute for the burn-in shift). Output: what to draw (strings, colors, arc angles, number of lit battery segments, AOD offset), the text layout of the date pill and bottom field, and which long-press target a touch point hits. Tested with Monkey C unit tests (`(:test)`) run in the simulator.
- Keep sensor reading and drawing thin; check them by eye in the simulator (against the design) and with the AOD heat map.

## Performance
Lesson from the previous face: Segment34 lagged when returning from menus because it redrew everything every second (~25 drawText calls with custom fonts + a gradient bitmap). Therefore:
- No seconds. Data updates once a minute, except heart rate, which is re-read every second while the screen is awake (high-power mode), the only time the full face is visible.
- Static parts (background, wells, tracks) are drawn once into a buffer.
- Use only the bitmap fonts needed, each containing only the glyphs in use.

## Agent skills

### Issue tracker

Issues live as markdown files under `.scratch/<feature>/`. See `docs/agents/issue-tracker.md`.

### Triage labels

The five default labels (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`), recorded on a `Status:` line. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `GLOSSARY.md` + `docs/adr/` at the repo root; existing decisions live in `docs/decisions.md`. See `docs/agents/domain.md`.
