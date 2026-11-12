# Design decisions (agreed 2026-11-12)

Source: the Q1–Q17 Q&A session with the user, plus the final design in Claude Design (`design/claude-design/FR265 Watch Face.dc.html`). When this document and the design disagree, follow **this document** for MVP scope and **the design** for pixel measurements.

## Background
- Previous faces: SHN EDO → Segment34 MkIII (dropped: ugly and laggy) → Focus Digital (by supeerb). On 2026-11-10 Focus Digital became paid ($2.75), so the user decided to build their own face.
- The user only uses free software. The watch is for checking daily health (Body Battery drains from riding a motorbike, stress, steps, intensity minutes), not for running.
- Inspired by Focus Digital (solid color blocks, big digits) and Dash PRO by Crafted.by.Mies (round gauges with rings, rounded pills). Both are closed source, so no code or assets are copied. Fonts come from Google Fonts (OFL).

## Decisions
| # | Topic | Decision |
|---|---|---|
| Q1/Q7 | Style, layout | Combine Focus + Dash. The final version uses the **Dash layout**: time on one line over a color band, 3 round gauges below |
| Q2 | Data, in priority order | Hours:minutes > Body Battery > stress > heart rate > steps/goal > weekday + date, plus battery %. No seconds, weather or notifications |
| — | Goals | Read from the watch (`stepGoal`, intensity-minutes goal), **never entered by hand** |
| Q6 | Step goal | Keep Garmin's **auto** mode |
| Q3 | Colors | 1 accent color (per theme) + warning colors. BB 15–24 orange `#FF8A3D`, <15 red `#FF4D4D`. Stress 51–75 orange, >75 red. Battery ≤20% orange, ≤10% red |
| Q4 | Bedtime countdown | **Not** in the MVP. Performance comes first |
| Q5 | Long-press on fields | Yes: opens the matching Garmin page (BB, left field, heart rate, steps) |
| Q8/Q16 | Time font | **Big Shoulders Display ExtraBold**, 57 px (digit height 46 px). LCD was chosen at first, but the user switched in Claude Design. Secondary font: **Manrope** ExtraBold/Bold |
| Q9 | Default accent | Mint `#8EE3B8`. This is only the first theme; more themes later |
| Q10 | Bezel | Step progress ring (no month-name ring) |
| Q11 | Field style | BB and stress are round gauges with a 0–100 ring. Heart rate is 5 HR-zone segments + the number |
| — | AOD | Time + date only, **same position and size**, everything else black |
| Q12 | AOD digits | **2 px outline** only, no fill, no dimmed background segments |
| Q13 | AOD color | Accent × 0.55 (mint → `#4E7D65`) |
| — | AOD burn-in protection | The whole time + date group shifts a few pixels each minute; ≤10% of pixels lit; verify with the heat map |
| Q14 | Morning sleep score | **Dropped**: the FR265 (API 5.2) doesn't expose it to CIQ faces |
| Q15 | Extras beyond the MVP (left field switchable to recovery / SpO₂ / altitude, sleep-mode dimming, properties.xml) | **Not** in the MVP. The left field is always stress. Leave room in the code to extend |
| Q17 | Background | Very dark gray `#1A1D1B` when the screen is on; pure black in AOD |
| — | Testing | The single test seam is `FaceModel` (see CLAUDE.md) |

## Implementation decisions (agreed 2026-11-12, second session)
Vocabulary follows `GLOSSARY.md`. These rows extend Q1–Q17; where one changes the design, the row says so.

| # | Topic | Decision |
|---|---|---|
| Q18 | Build order | Start with a tracer bullet (background, time band, time in a system font) that goes the whole way: build → sign → simulator → sideload to the watch. Then add elements one by one |
| Q19 | Process | Short spec plus one ticket per step under `.scratch/mvp/` before coding |
| Q20 | Git | Commit straight to `master`, no feature branches (changed 2026-11-12; was one `feat/<slug>` branch per ticket). Commit only with the user's approval |
| Q21 | Date language | Weekday name follows the watch language, upper-cased with diacritics stripped. If a character is still missing from the font (Cyrillic, CJK…), fall back to English. Vietnamese weekdays use their short form: "Thứ 2"…"Thứ 7" → `T2`…`T7`, Sunday → `CN` (2026-11-13). The watch is currently set to English |
| Q22 | Time format | Always 24 h with a leading zero (`08:42`), whatever the watch's 12/24 h setting |
| Q23 | Date pill width | At least 96 px, grows to fit longer weekday names, stays centered, never wider than the time band |
| Q24 | Bottom field, goal not reached | If the step text doesn't fit, the step number shrinks from 22 to 18. If it still doesn't fit, the foot icon is hidden |
| Q25 | Bottom field, goal reached | `/ goal` is dropped: foot icon + step number, centered as a group, on the accent with black text. **Changes design frame 7** (`3.512 / 3.110` → `3.512`) |
| Q26 | Missing data | Body Battery: `--` in gray, track only. No step goal (missing or 0): bezel ring empty and no `/ goal`. No battery reading: all 10 segments off |
| Q27 | Intensity minutes | **Not** in the MVP |
| Q28 | AOD burn-in shift | Time + date cycle through offsets of at most ±4 px, one step per minute. Verified with the heat map |
| Q29 | Fields and metrics | Fields are named by position: left, center, right, bottom field and bezel ring. A field is only a place, size and well; the **metric** decides how it is drawn (gauge, zone segments, progress). The bezel ring only takes a goal metric. The MVP maps metrics to fields statically: stress → left, Body Battery → center, heart rate → right, steps → bottom field and bezel ring |
| Q30 | Test seam | `FaceModel` stays the only test seam. Besides colors, strings, angles and segment counts it also computes the text layout of the date pill and the bottom field (from glyph-width tables generated with the fonts), the AOD burn-in offset, and which long-press target a touch point hits. Sensor reading, drawing and the font generator are checked by eye in the simulator |
| Q31 | Up-to-date stack | Everything used is current, nothing outdated: the latest Connect IQ SDK, the newest API level the FR265 supports (5.2, its firmware ceiling) as `minApiLevel`, no deprecated APIs (checked against the SDK docs), strict type checking, the latest stable versions of every tool and library, and fonts freshly downloaded from Google Fonts. Re-check versions at the start of each ticket |
| Q32 | Font glyph sets | Each font contains only the glyphs it draws (see "Fonts to export"). `%` and `h` are dropped until a Q15 metric needs them |
| Q33 | Date too long | If the weekday name does not fit even in a date pill as wide as the time band (272 px), the English abbreviation is used |
| Q34 | Bottom field last resort | If the step text still does not fit after shrinking the number and hiding the icon (only possible from 100.000 steps), `/ goal` is dropped |
| Q35 | AMOLED rule | Acceptance criterion for AOD: **less than 10% of screen luminance**, measured with the simulator heat map (the SDK rule since the Venu 2). The hard "no pixel lit > 3 minutes" requirement is dropped. The ±4 px burn-in shift (Q28) stays, as Garmin recommends, to limit physical burn-in |
| Q36 | Heart-rate refresh | While the screen is awake (high-power mode), heart rate alone is re-read every second and the right field updates when it changes. All other data stays once a minute and on wake. AOD shows no heart rate, so nothing is read there |
| Q37 | Heart-rate zone colors (agreed 2026-11-13, ticket 09) | Each lit zone segment takes its own zone's color, in Garmin's order: zone 1 gray `#B4B4B4`, 2 blue `#4DA6FF`, 3 green `#4CD964`, 4 orange `#FF8A3D`, 5 red `#FF4D4D`. Garmin's manuals name the colors but publish no values; these were chosen for the dark background, and zones 4 and 5 reuse the warning colors on purpose. The colors are a theme role. Replaces the accent for lit zone segments (Q3 otherwise unchanged) |

## Final design: main elements
Coordinates are on the 416×416 canvas, center (208,208). Full details in `spec` inside the design file.
- **Step ring:** arc r 204, stroke 8, starts at 12 o'clock, runs clockwise, angle = min(1, steps/goal) × 360°. Track `#1E1E1E`. 3 black notches at 90/180/270°. White dot r 4 at the ring's head.
- **Background:** fillCircle r 194, color `#1A1D1B`. Draw order: ring → background → wells → content. A well is a 6 px black border around each element.
- **Battery:** 10 arc segments r 180, stroke 4, spanning −34°…+34°, 1.6° gaps. Well: arc stroke 12 with 2 round caps. Lit segments = ceil(battery/10). Off segments `#2E3330`.
- **Time band:** roundRect (72,80,272,64) radius 20, accent color. Time in black, centered on x 208.
- **Date:** pill (160,140,96,28) radius 14, overlapping the bottom edge of the time band. Manrope ExtraBold 17, letter spacing 1.5, white text. Format `THU 12`.
- **Left field (stress):** center (88,236) R 38. Ring stroke 6. Icon 24 px. Manrope number 26, size shrinks with character count (≤3 → 26, 4 → 22, ≥5 → 18).
- **Body Battery:** center (208,246) R 60. Ring stroke 9. Lightning-bolt icon. Manrope number 48.
- **Heart rate:** center (328,236) R 38. 5 arc segments (i×72°+4° → (i+1)×72°−4°). Lit segments = number of HR-zone thresholds ≤ heart rate (zones from `UserProfile.getHeartRateZones`), each in its zone's color (Q37). No data: `--` in gray.
- **Steps:** pill (126,320,164,40) radius 20. Manrope number 22 right-aligned at x 228, `/ goal` Bold 15. Thousands separator is a dot (e.g. `1.147`). When the goal is reached: pill background switches to the accent color, text black.
- **Color rule:** the accent color is used only for the time band and progress. Icons are gray `#8C8C8C` and only change color on a warning.
- **Missing data:** stress or HR shows `--` in gray, ring off.
- **Fonts to export:** time font as filled + outline (AOD) with glyphs `0–9 :`. Manrope at sizes 15/17/18/22/26/48, each with only the glyphs it draws (Q32): ExtraBold 17 `A–Z 0–9` + space; ExtraBold 18 and 22 `0–9 . -`; ExtraBold 26 and 48 `0–9 -`; Bold 15 `0–9 . /` + space. No `%` or `h` until a Q15 metric is built.
