# Design sync: where the built face differs from the final design

The final design is `design/claude-design/FR265 Watch Face.dc.html` (Claude Design). This file lists where the face on the watch still differs from it, so the design can be brought up to date. When a change departs from the design, add a row under "Open differences"; when the design catches up, move it to "Resolved".

## Open differences

| Element | Design | Built face | Source |
|---|---|---|---|
| Bottom field from 100.000 steps | Always hides the foot and drops `/ goal`, number centered on x 208 | Drops `/ goal` only when number + 5 px + `/ goal` is still wider than 136 px. With a short goal it stays: `100.000 / 3.110` and `123.456 / 10.000` keep `/ goal` centered; `100.000 / 200.000` drops it | Q34, ticket 10 |
| Bezel head dot | At the exact fraction of the goal | At the whole-degree end of the progress arc, up to 1° (about 3.6 px) behind | spec, ticket 06 |
| Text widths | Measured with the browser's Manrope, so pill widths and centered groups can differ by about 1 px | Measured with the generated bitmap fonts' glyph-width tables | spec |
| Date fallback | Not shown | A weekday name that needs a pill wider than 272 px, or has letters the date font lacks (Cyrillic, CJK), falls back to the English abbreviation (`THU 12`) | Q21, Q33, ticket 05 |

Only the first row changes what the face shows in practice, and only past 100.000 steps in a day.

## Resolved

By the design update of 2026-11-13 ("KHỚP MVP 13/11/2026"), which followed the first version of this list:

- Heart-rate zone segments in their own zone colors (Q37), frame 5.
- Goal reached without `/ goal`, foot and number centered as a group (Q25), frame 7.
- Vietnamese date `T5 12`, pill width max(96, text + 2 × 14) up to 272 (Q21, Q23).
- Date letter spacing 2 px; no extra spacing on `--`.
- Big Shoulders (current variable file, wght 800, opsz 72) with tabular digits: 28 px each, `:` 14 px, `08:42` 126 px.
- Missing data for every metric and the battery, frame 11; bottom-field fit rules, new frame 11b (Q24, Q26).
- Battery segments in whole degrees: −34 + 7i to −29 + 7i.
- Always On burn-in shift (12 offsets within ±4 px, Q28) and the hold-zone note for Always On.
- Frames 4, 6, 8, 9 and 10 marked "after the MVP" (Q14, Q15).
