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

## Final design: main elements
Coordinates are on the 416×416 canvas, center (208,208). Full details in `spec` inside the design file.
- **Step ring:** arc r 204, stroke 8, starts at 12 o'clock, runs clockwise, angle = min(1, steps/goal) × 360°. Track `#1E1E1E`. 3 black notches at 90/180/270°. White dot r 4 at the ring's head.
- **Background:** fillCircle r 194, color `#1A1D1B`. Draw order: ring → background → wells → content. A well is a 6 px black border around each element.
- **Battery:** 10 arc segments r 180, stroke 4, spanning −34°…+34°, 1.6° gaps. Well: arc stroke 12 with 2 round caps. Lit segments = ceil(battery/10). Off segments `#2E3330`.
- **Time band:** roundRect (72,80,272,64) radius 20, accent color. Time in black, centered on x 208.
- **Date:** pill (160,140,96,28) radius 14, overlapping the bottom edge of the time band. Manrope ExtraBold 17, letter spacing 1.5, white text. Format `THU 12`.
- **Left field (stress):** center (88,236) R 38. Ring stroke 6. Icon 24 px. Manrope number 26, size shrinks with character count (≤3 → 26, 4 → 22, ≥5 → 18).
- **Body Battery:** center (208,246) R 60. Ring stroke 9. Lightning-bolt icon. Manrope number 48.
- **Heart rate:** center (328,236) R 38. 5 arc segments (i×72°+4° → (i+1)×72°−4°). Lit segments = number of HR-zone thresholds ≤ heart rate (zones from `UserProfile.getHeartRateZones`). No data: `--` in gray.
- **Steps:** pill (126,320,164,40) radius 20. Manrope number 22 right-aligned at x 228, `/ goal` Bold 15. Thousands separator is a dot (e.g. `1.147`). When the goal is reached: pill background switches to the accent color, text black.
- **Color rule:** the accent color is used only for the time band and progress. Icons are gray `#8C8C8C` and only change color on a warning.
- **Missing data:** stress or HR shows `--` in gray, ring off.
- **Fonts to export:** time font as filled + outline (AOD) with glyphs `0–9 :`. Manrope at sizes 15/17/18/22/26/48 with glyphs `0–9 A–Z / . - % h`.
