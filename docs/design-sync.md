# Design sync: where the built face differs from the final design

The final design is `design/claude-design/FR265 Watch Face.dc.html` (Claude Design). This file lists where the face on the watch still differs from it, so the design can be brought up to date. When a change departs from the design, add a row under "Open differences"; when the design catches up, move it to "Resolved".

## Open differences

| Element | Design | Built face | Source |
|---|---|---|---|
| Bottom field from 100.000 steps | Always hides the foot and drops `/ goal`, number centered on x 208 | Drops `/ goal` only when number + 5 px + `/ goal` is still wider than 136 px. With a short goal it stays: `100.000 / 3.110` and `123.456 / 10.000` keep `/ goal` centered; `100.000 / 200.000` drops it | Q34, ticket 10 |
| Gauge end (round cap, Body Battery dot) | At value × 3.6° exactly | At the whole-degree end of the gauge arc, up to 1° behind (at most about 0.9 px on the center ring, 0.6 px on the side rings), centers in whole pixels; cap and dot always sit on the drawn arc's end. Body Battery 56: design (188.12, 312.21), face (189, 312) | second design update ticket 05 |
| Text widths | Measured with the browser's Manrope, so pill widths and centered groups can differ by about 1 px | Measured with the glyph widths of the generated bitmap fonts (the font catalog) | spec |
| Date fallback | Not shown | A weekday name that needs a pill wider than 272 px, or has letters the date font lacks (Cyrillic, CJK), falls back to the English abbreviation (`THU 12/11`) | Q21, Q33, Q38, ticket 05 |
| Two-color date, weekday with a space | Splits the date at its first space, so only the first word of a weekday name with a space is in the accent | The whole weekday (everything before the day/month) is in the accent. Seen only in languages whose folded weekday name keeps a space; Vietnamese names are shortened to T2–T7 and CN first | Q21, Q38, second design update ticket 04 |
| Bezel tick endpoints | Fractional, `polar` rounded to 0.01 px | Whole pixels: the exact position (208 + r·sin, 208 − r·cos) rounded half up, because `drawLine` drops the fraction of its endpoints (simulator, SDK 9.3.0). Four ordinary ticks (i = 7, 22, 23, 38) have one inner-end coordinate at 342.495: the face draws 342, where rounding the design's 342.50 would give 343 | second design update ticket 06 |
| Lit bezel ticks | Each tick drawn once, lit or unlit | Unlit ticks sit in the static layer and lit ticks are drawn over them, so their anti-aliased edges can differ slightly from the design; the lead tick, longer and at least pen 4, covers its unlit tick | second design update ticket 06 |
| Time position | `08:42` starts at x 113.5 | Whole pixels: starts at x 114 (208 − 189 / 2 in integer math), half a pixel to the right | Q8/Q16, second design update ticket 03 |

Only the first row changes what the face shows noticeably, and only past 100.000 steps in a day.

## Resolved

By the design update of 2026-11-13 ("KHỚP MVP 13/11/2026"), which followed the first version of this list:

- Heart-rate zone segments in their own zone colors (Q37), frame 5.
- Goal reached without `/ goal`, foot and number centered as a group (Q25), frame 7.
- Vietnamese date `T5 12` (superseded 2026-11-14 by `T5 12/11`, Q38), pill width max(96, text + 2 × 14) up to 272 (Q21, Q23).
- Date letter spacing 2 px; no extra spacing on `--`.
- Big Shoulders (current variable file, wght 800, opsz 72) with tabular digits: 28 px each, `:` 14 px, `08:42` 126 px (superseded 2026-11-14: 38 px, 19 px, 171 px, Q8/Q16).
- Missing data for every metric and the battery, frame 11; bottom-field fit rules, new frame 11b (Q24, Q26).
- Battery segments in whole degrees: −34 + 7i to −29 + 7i.
- Always On burn-in shift (12 offsets within ±4 px, Q28) and the hold-zone note for Always On.
- Frames 4, 6, 8, 9 and 10 marked "after the MVP" (Q14, Q15).

By the second design update of 2026-11-14 ("CẬP NHẬT 14/11/2026"), built in its tickets 05 and 06:

- Bezel head dot: gone with the bezel ticks (ticket 06); the lead tick sits on the tick the progress has reached, as in the design.
- Center field gauge: centerline r 54 (60 − 12 / 2), pen 12, a whole number, so the face draws it exactly; it was r 56, pen 9, against the design's r 55.5.
