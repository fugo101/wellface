# Brief given to Claude Design (2026-11-12)

Records the original intent. The final version differs from this brief (time font, gray background, extra frames beyond the MVP); what was agreed lives in `decisions.md`.

The brief was originally written in Vietnamese; below is an English translation.

```
Design a watch face for the Garmin Forerunner 265: round AMOLED screen, 416×416 px, black background #000000.
The face is for personal use only and will be programmed in Monkey C (Connect IQ), so it must respect the technical limits below.

## Style
Combine 2 Garmin faces: "Focus Digital" (7-segment LCD time digits, large solid color blocks) and "Dash PRO"
(clean, modern, data fields as round gauges with progress rings, small details as rounded pills).
- Time digits: 7-segment LCD font, 24h, NO seconds.
- Secondary text: one modern sans font, medium-bold.
- Single accent color: mint/pistachio green (suggested #8EE3B8). Text: white and gray.
- Warning colors: Body Battery 15–24 → orange #FF8A3D, below 15 → red #FF4D4D; Stress 51–75 → orange, above 75 → red.

## Data (in priority order, sample values)
1. Hours:minutes 08:42  2. Body Battery 56 (0–100 ring)  3. Stress 27 (0–100 ring)  4. Heart rate 62
5. Steps: ring around the bezel = steps / goal (1.147 / 3.110)  6. Weekday + date THU 12 (pill)  7. Battery % 78%

## 2 layouts: A Focus layout (color block on the right half, stacked time) · B Dash layout (time on one line over a color band, round gauges below)
## Each layout has 3 frames: Normal · Warning · Always On (time + date only, thin 2–3 px outline, mint dimmed to ~55%, ≤10% of pixels lit)
## Limits: text/lines/rectangles/circles/arcs/monochrome icons; no gradients, shadows, blur or transparency; at most 2 fonts; margins ≥20 px; mark the long-press areas
## Also export a spec table: x, y, width, height, font/size, hex color, data, warning condition; time-font specs
```
