# Wellface

A custom watch face for a round AMOLED Garmin watch. Every element sits inside a black well. Colors come from a theme, so no term here is tied to a specific color.

## Look and color

**Well**:
The black area that surrounds an element and separates it from the background. A black pill can be its own well.
_Avoid_: Frame, outline, border

**Theme**:
A named set of colors used to draw the face. The face has exactly one active theme.
_Avoid_: Skin, color scheme

**Accent**:
The theme's main color, used only for the time band, for progress (rings, lit segments), for a field whose goal is reached, and (dimmed) for AOD.
_Avoid_: Mint, primary color, highlight

**Warning color**:
The orange or red color an element switches to when its value crosses a threshold.
_Avoid_: Alert color, error color

## Fixed elements

**Time band**:
The rounded band, filled with the accent, that holds hours:minutes.
_Avoid_: Time bar, header

**Date pill**:
The small rounded pill under the time band that shows the weekday and day of month.
_Avoid_: Date field, date badge

**Battery bar**:
The ten segments at the top that show the watch battery level.
_Avoid_: Battery gauge, battery ring

## Fields and metrics

**Field**:
A fixed place on the face, with its own size and well, that shows one metric. Fields are named by position, never by the metric they show.
_Avoid_: Slot, cell, widget, complication

**Metric**:
A piece of health or activity data shown in a field, such as stress, Body Battery, heart rate or steps. The metric decides how its value is drawn inside the field.
_Avoid_: Data field, stat, value

**Goal metric**:
A metric that has a goal read from the watch, so its value can be shown as progress toward that goal (for example steps).
_Avoid_: Target metric

**Left field**:
The small round field on the left.
_Avoid_: Stress field, stress gauge

**Center field**:
The large round field in the middle.
_Avoid_: Body Battery field, main gauge

**Right field**:
The small round field on the right.
_Avoid_: Heart-rate field, HR gauge

**Bottom field**:
The wide pill at the bottom.
_Avoid_: Step pill, steps field

**Bezel ring**:
The ring around the edge of the face. It only shows a goal metric, as progress.
_Avoid_: Step ring, outer ring, progress ring

**Gauge**:
A ring inside a field that fills from 0 to 100 according to the metric's value.
_Avoid_: Dial, meter

**Zone segments**:
Five ring segments that light up one per heart-rate zone reached.
_Avoid_: HR gauge, zone ring

## Modes and interaction

**AOD**:
Always On mode: the low-power screen state where only the time and date are drawn, dimmed.
_Avoid_: Sleep mode, low-power mode, ambient mode

**Burn-in shift**:
The small per-minute movement of the time and date in AOD so no pixel stays lit too long.
_Avoid_: Pixel shift, jitter

**Long-press target**:
An area of the face that opens the matching Garmin page when held.
_Avoid_: Tap zone, hotspot
