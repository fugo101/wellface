# Wellface spec

What the face does today: layout, fields, metrics, themes, Always On, long press, data reading, drawing and testing. It describes the current build, not how it got there.

Sources of truth, in this order when they disagree:

1. `docs/decisions.md` (Q1–Q53) for scope and behavior. Q numbers below refer to it.
2. The code in `source/` and `tests/`. Every value in this spec was checked against it.
3. The final design, `design/claude-design/FR265 Watch Face.dc.html` (`buildG` and the `spec` array), for pixel measurements. `docs/design-sync.md` lists where the built face deliberately differs from it.

`GLOSSARY.md` defines the vocabulary (well, well rim, field, field kind, drawing style, metric, face config, bezel tick, lead tick, contour texture, accent, theme). Platform facts and their sources are in `docs/research/connect-iq-platform.md`. Build, test and sideload commands are in `docs/build.md`.

## Scope

- Device: Garmin Forerunner 265 (`fr265`), round 416×416 AMOLED, Connect IQ API 5.2 (`minApiLevel` 5.2.0). Watch face app type. Permissions: `ComplicationSubscriber` and `UserProfile` (heart-rate zones).
- **The layout is for 416×416 round AMOLED only.** Every coordinate below is on that canvas, center (208, 208). Other resolutions (starting with the FR265S at 360×360) are planned through the multi-device work. Until then, `source/Layout.mc` holds FR265 geometry only.
- Sideloaded, so there is no settings page in the phone app. All configuration is the built-in face config (see "Face config").
- Shown: hours:minutes, seconds while awake, weekday and date, watch battery, stress, Body Battery, heart rate with zones, and steps toward the watch's own step goal (Q2). The step goal is always read from the watch, never entered (Q6).
- Not built: intensity minutes (Q27), sleep score (needs API 6.0.2), HRV status, Training Readiness, weather, notifications, bedtime countdown (Q4), recovery time, Pulse Ox, altitude, sleep-mode dimming (Q15), an on-watch settings menu.

## Layout

Fields are named by position: left, center, right, bottom field, and the bezel ring (Q29). A field is only a place, a size and a well. The metric shown in it decides how it is drawn.

### Drawing order

Back to front:

1. Black screen, then the background disc.
2. The contour texture.
3. The edge mask.
4. The unlit bezel ticks.
5. The well rims.
6. The battery well and its unlit segments.
7. The time band's well and the time band.
8. The round fields' wells and tracks.
9. The frame content: lit bezel ticks, lit battery segments, the round fields' arcs, caps, icons and numbers, the bottom field, the time, the seconds, then the date pill and date.

Items 1–8 form the static layer.

### Geometry

| Element | Geometry |
|---|---|
| Background disc | fillCircle r 194 |
| Edge mask | black ring r 201, pen 14, over r 194–208 |
| Bezel ticks | 60 radial lines, tick i at 6i° clockwise from 12 o'clock, each from its inner radius to r 208, flat ends. Ordinary: inner r 201, pen 3. Every 5th: r 198, pen 4. At 12/3/6/9 o'clock (i = 0, 15, 30, 45): r 196, pen 5. Lead tick: from r 195, pen max(4, own pen). Endpoints rounded half up to whole pixels |
| Battery bar | 10 arc segments r 180, pen 4, flat ends. Segment i spans −34 + 7i° to −29 + 7i° (design degrees), leftmost first. Well: arc r 180, pen 12, from −36° to +36°, with a black round cap r 6 at each end. No rim |
| Time band | rounded rect (64, 78, 288, 88), radius 24, accent. Well (58, 72, 300, 100) radius 30. Rim (56, 70, 304, 104) radius 32 |
| Time | centered on x 208, baseline y 155. `08:42` is 189 px wide and starts at x 114 |
| Seconds | left-aligned at x 309, baseline y 155 |
| Date pill | top y 162, height 28, radius 14, centered on x 208, width max(96, text width + 2 × 14), at most 272. Overlaps the bottom edge of the time band. Text capitals centered on y 176. No rim |
| Left field | circle (88, 252) R 38. Ring centerline r 35, pen 6. Icon top-left (76, 222). Number digits centered on y 266 |
| Center field | circle (208, 262) R 60. Ring centerline r 54, pen 12. Icon top-left (196, 219). Number digits centered on y 274 |
| Right field | circle (328, 252) R 38. Ring centerline r 35, pen 6. Icon top-left (316, 222). Number digits centered on y 266 |
| Round field wells | circle R + 6. Rims: circle R + 8 |
| Bottom field | pill (126, 336, 164, 40), radius 20, 8 px below the center field's well. The black or accent pill is its own well. Rim (124, 334, 168, 44) radius 22 |

Wells are 6 px of black around an element. Well rims are 2 px outside the well (Q39). Icons are 24 px glyphs.

### Arc contract

The design and `docs/decisions.md` use design degrees: 0° is 12 o'clock, clockwise positive. FaceModel emits Connect IQ `drawArc` degrees, `(90 − design) mod 360`, always drawn clockwise.

Rules:

- A sweep of 0 draws nothing and a sweep of 360 is a full circle.
- Sweeps use integer math, rounded down. A gauge sweep is clamp(value, 0, 100) × 360 / 100.
- Every gauge arc and zone segment, lit or unlit, has round caps. A cap is a filled circle of radius pen / 2 at each end, on the centerline. A full circle has no caps.
- Counted things keep flat ends: bezel ticks and battery segments (Q11).
- Gauge ends sit at the whole-degree end of the arc, up to 1° behind the design's exact value (design-sync).

## Fields and metrics

### Metrics

Everything about a metric is described once, in `source/Metric.mc`. No other module switches on the metric.

| Metric | Drawing style | Icon | Value source | Read cadence (awake) | Warnings (Q3) | Number format | Long press opens |
|---|---|---|---|---|---|---|---|
| Stress | gauge 0–100 | stress | complication, polled | once a minute and on wake | orange above 50, red above 75 | plain | stress |
| Body Battery | gauge 0–100, white end dot | bolt | complication, polled | once a minute and on wake | orange below 25, red below 15 | plain | Body Battery |
| Heart rate | zone segments | heart | complication, polled | every update (about once a second) | none (zone colors) | plain | heart rate |
| Steps | goal progress | foot | `ActivityMonitor.getInfo().steps` and `.stepGoal` | once a minute and on wake | none | dot every three digits (`1.147`) | steps |

Further rules:

- A negative reading of any metric or goal counts as missing. The data reader keeps only whole numbers.
- Steps are read from the activity info rather than the steps complication, which changes type in wheelchair mode.
- A goal metric is exactly a metric drawn as goal progress. Steps is the only one.

### Field kinds (Q40)

| Field kind | Fields | Accepts |
|---|---|---|
| Round field | left, center, right | gauge, zone segments (stress, Body Battery, heart rate) |
| Bottom field | bottom | goal progress (steps) |
| Bezel ring | bezel ring | goal progress (steps) |

A field asked for a metric it cannot draw shows its default metric instead. The defaults are stress on the left, Body Battery in the center, heart rate on the right, and steps on the bottom field and the bezel ring. The same metric may appear in several fields. There is no empty field.

### Round fields

The geometry stays with the position: well, rim, ring radius and pen, icon slot, number slot and number size. The look comes from the metric: track kind, lit arcs, icon, number and colors.

- **Gauge:**
  - The track is a full ring in the gauge track color.
  - The lit arc runs from 12 o'clock clockwise, in the accent or the warning color. No arc at 0.
  - Body Battery adds a white dot r 3 at the arc's end, only when the value is above 0.
- **Zone segments:**
  - Five segments. Segment i (zone i + 1) spans i × 72 + 9° to (i + 1) × 72 − 9°. That leaves 18° between segments, about 8° visible past the caps on a pen-6 ring.
  - The track is the five segments in the gauge track color.
  - Lit = the number of zone lower bounds at or below the heart rate. Lit segment i takes zone i + 1's color (Q37).
  - Zones come from `UserProfile.getHeartRateZones(HR_ZONE_SPORT_GENERIC)`, indexes 0–4. If the zones are missing, nothing is lit but the number still shows.
- **Warnings:** the arc, icon and number all take the warning color. Without a warning, the icon is gray and the number white.
- **Number size:**
  - The center field is always 48 px.
  - The left and right fields shrink with the character count: 26 px up to 3 characters, 22 px for 4, 18 px for 5 or more.
- **Missing value:** `--` in gray, the track only, the icon gray.

### Bottom field

Goal not reached:

- The pill is black.
- The foot icon is gray at (140, 344). The number is white, in 22 px, right-aligned at x 228, digits centered on y 356. `/ goal` is gray, Manrope Bold 15, left-aligned at x 233, centered on y 357.
- The text fits when the number starts at x 164 or later and the goal ends at x 286 or earlier.
- If it does not fit, the number drops to 18 px at the same anchors (Q24).
- If it still does not fit, the icon is hidden and number + 5 px + `/ goal` is centered on x 208, at 18 px, within x 140–276.
- If even that does not fit, `/ goal` is dropped (Q34). This only happens from 100.000 steps, and only when the goal is long too (design-sync).

Goal reached (goal above 0, steps known and at least the goal; Q25):

- The pill takes the accent.
- The foot icon and number are black, without `/ goal`.
- The icon's 24 px box, a 4 px gap and the number are centered on x 208 as a group, at 22 px, or 18 px if the group is wider than 136 px.

Missing data:

- Missing steps: `--` in gray, plus `/ goal` if the goal is above 0.
- Missing goal or goal 0: no `/ goal`, never reached (Q26).

### Bezel ring (Q10)

The ring shows progress of its goal metric (steps) toward the goal.

- **Lit count:**
  - n = 0 when steps or the goal is missing, the goal is 0, or steps is 0.
  - Otherwise n = min(60, floor(steps × 60 / goal) + 1).
  - So tick i lights once progress reaches i/60, and the 3, 6 and 9 o'clock ticks light exactly at 25, 50 and 75%.
- **Before the goal:**
  - Ticks 0 … n − 2 take the comet colors. Tick i is each accent channel × (0.45 + 0.55 × (i + 1) / n), computed in double precision in that order and rounded half up, which matches the design's JavaScript in every theme.
  - Tick n − 1 is the white lead tick, longer and at least pen 4.
- **Goal reached:** all 60 ticks take the accent and there is no lead tick.
- **No progress:** all 60 ticks stay unlit in their tier colors.
- **Drawing:** lit ticks are drawn over the unlit ticks of the static layer.

### Battery bar

- Lit segments = (battery + 9) / 10 in integer math, clamped to 0–10, filling from the left.
- Lit segments take the accent, orange at 20% or less, red at 10% or less.
- Missing battery: all 10 segments unlit.
- The battery is `System.getSystemStats().battery`, rounded half up and clamped to 0–100.

## Time and date

- **Time:**
  - Always 24 h with a leading zero (`08:42`), whatever the watch setting (Q22).
  - Big Shoulders Display ExtraBold, 86 px, tabular: every digit is 42 px wide and the colon 21 px (Q8/Q16).
  - Black on the time band.
  - The position comes from the measured width and the font's base, so `08:42` starts at x 114 against the design's 113.5 (design-sync).
- **Seconds (Q41):**
  - Two digits from a fixed `00`…`59` table, so nothing is allocated per second.
  - Manrope ExtraBold 26, black, at a fixed x 309, so hours:minutes never move.
  - Shown only while the face gets per-second updates (between `onExitSleep` and `onEnterSleep`). On the FR265 those updates stop about 10 s after a wake even when a tap keeps the screen lit. The seconds are then hidden, not frozen.
  - Never shown in AOD.
- **Date (Q21, Q38):**
  - The text is the weekday, a space, then `dd/mm` with two digits each (`THU 12/11`), in every language and whatever the watch's date format.
  - The weekday is the watch's localized name (`FORMAT_MEDIUM`), folded code point by code point to A–Z. Spaces and digits are kept and combining marks dropped. Accented Latin and Vietnamese letters map to their base letter.
  - Vietnamese names are then shortened: `THU 2` … `THU 7` to `T2` … `T7`, and `CHU NHAT` to `CN`.
  - The English abbreviation from the weekday number is used when the name is missing or empty, keeps a character the date font lacks (Cyrillic, CJK), or would need a pill wider than 272 px (Q33).
  - Drawn as two runs: the weekday in the accent and the day/month in white, centered as one group.
  - The text's width counts the 2 px letter spacing only between characters, not after the last one.
- **Calendar reading:** the clock is read on every update. The full calendar (hour, minute, date, weekday and weekday name) is read only when the hour or minute changes, all from one reading, so the date never disagrees with the time.

## Colors and themes (Q42)

A theme is one accent C. Every themed color is derived from it: each RGB channel × factor, rounded half up in integer math.

| Role | Factor | Mint value |
|---|---|---|
| Accent: time band, weekday, gauges, lit battery segments, lit ticks once the goal is reached, goal-reached bottom field | 1 | `#8EE3B8` |
| Background disc (Q17) | 0.24 | `#22362C` |
| Contour texture (Q43) | 0.36 | `#335242` |
| Well rim (Q39) | 0.48 | `#446D58` |
| Comet base, the dim end of the lit ticks, never drawn alone | 0.45 | `#406653` |
| Always On time and date (Q13) | 0.75 | `#6BAA8A` |

Fixed in every theme:

| Role | Value |
|---|---|
| Ink: wells, edge mask, time, seconds, date pill and bottom field fill | `#000000` |
| Text: numbers, day/month, lead tick, Body Battery dot | `#FFFFFF` |
| Secondary: icons without a warning, `/ goal`, `--` | `#8C8C8C` |
| Gauge track: unlit gauges, zone segments and battery segments | `#2E3330` |
| Unlit bezel ticks: ordinary, every 5th, 12/3/6/9 o'clock | `#343B37`, `#4A524D`, `#69736D` |
| Warning level 1 / level 2 | `#FF8A3D` / `#FF4D4D` |
| Zones 1–5 (Q37) | `#B4B4B4`, `#4DA6FF`, `#4CD964`, `#FF8A3D`, `#FF4D4D` |

The ten themes and their accents:

| Theme | Accent |
|---|---|
| Mint | `#8EE3B8` |
| Volt | `#D4F26A` |
| Sage | `#B4CDA0` |
| Aqua | `#66E0F0` |
| Glacier | `#8CCFFF` |
| Steel | `#A9BDD4` |
| Periwinkle | `#A3B4FF` |
| Lavender | `#B9A8FF` |
| Orchid | `#E2A9F3` |
| Platinum | `#D5DBE0` |

Mint is the default theme (Q9): an unknown theme name resolves to it. AOD black is a platform rule, not a theme color.

## Face config

A face config is a theme name plus one metric for each of the five fields. It is a plain value, so future settings only need to build one.

- **Resolving:** `FaceModel.resolve` looks up the theme by name (an unknown name gives Mint). It applies the field-kind fallback per field. Every other FaceModel entry point takes the resolved config.
- **Built-in config:** `FaceConfigs.defaultConfig` holds stress, Body Battery, heart rate, steps and steps. Its theme name is the active theme, currently Platinum. Changing the theme means editing that one line and sideloading again.
- **Applying:** the view has one apply-config path, also used at startup. It:
  - resolves the config;
  - builds the static layer and hands it to the renderer, which repaints its static buffer once;
  - drops both cached frames;
  - sets the read plan;
  - makes the next high-power update count as a wake, so every metric shown (and the zones, if needed) is read before the next frame.
- **Accepted metrics:** `FaceModel.acceptedMetrics(field)` lists what each field accepts, for a future settings menu.

## Data reading

The data reader is thin and untested. It builds a snapshot and reports what changed as change kinds.

- **Read plan:** derived from the resolved face config (`FaceModel.readPlan`).
  - Metrics read every high-power update: the metrics shown that read every second (heart rate).
  - Metrics read once a minute and on wake: the other metrics shown, a goal metric with its goal.
  - Zones: read on a wake when a field draws zone segments.
  - The battery is always read once a minute and on wake. Metrics not shown are not read.
- **Wake:** the first high-power update after an update that was not high power, after the screen was off, at start, or after a new read plan.
- **In AOD:** only the clock is read, no sensors (Q36).
- **Complications:** polled with `Complications.getComplication(id).value`, not subscribed. Each read is guarded, and anything that is not a whole number counts as missing.

Change kinds (bits) and the frame parts each one makes stale:

| Change kind | Meaning | Parts invalidated |
|---|---|---|
| `CHANGE_SECOND` | the clock's second, high power only | the seconds only |
| `CHANGE_CLOCK` | hour, minute, date or weekday name | time, date, AOD frame |
| `CHANGE_MINUTE_DATA` | battery, once-a-minute metrics, zones | battery bar, bezel ring, bottom field, each round field whose metric reads once a minute or draws zone segments |
| `CHANGE_PER_SECOND` | a metric read every second | only the fields showing such a metric |

A face config change counts as every change kind. Neither minute data nor per-second metrics touch the AOD frame.

## Refresh and drawing (Q41, Q43, Q44)

The FaceModel side:

- The view keeps one cached frame per mode, with the union of change kinds seen since it was last computed.
- `FaceModel.update` and `updateAod` recompute only the invalidated parts. Their result must equal a full `compute` or `computeAod`.
- A change of the second alone takes a fast path: it sets the seconds' text and touches nothing else.
- A second never makes the AOD frame stale.
- FaceModel also answers:
  - which parts change every second: the seconds, plus each field showing heart rate;
  - which parts change at most once a minute: all the others;
  - whether a set of change kinds makes the minute layer stale (`minuteLayerChanged`).

The renderer's tiers, high power only:

- **Static buffer:** a full-color, locked, full-screen buffer. It holds the static layer, contour texture included. It is painted once per applied face config and after each face start.
- **Minute layer:** a second full-color buffer. It holds the static layer plus every part that changes at most once a minute. It is rebuilt only when `minuteLayerChanged` says so, after a new static layer, or when the buffer is new. Each second it is copied to the screen, and only the every-second parts (the seconds, the field showing heart rate) are drawn over it.
- **Stale frames go straight to the screen:** drawing into a buffer is about 2.5 times slower than drawing on the screen on the FR265. So a frame whose minute layer is stale (a face start, a wake, a new minute, a new face config) is drawn directly on the screen, as a full repaint would be. The buffers are painted on the following updates, at most one per update.
- **Asleep with the screen lit:** while the face sleeps, every update is shown at once and the minute layer is not rebuilt.
- **No room in the graphics pool:** if a buffer cannot be had, every update is a full repaint, logged once. The face asks for the buffers again only at the next wake, show or face config. A full repaint without a static buffer leaves out the contour texture, or it would be drawn every second.
- **Cost limits (Q44):**
  - The per-second high-power update is at most 10% slower than the face without seconds.
  - AOD does no extra work.
  - The first frame after a return from a widget is no slower than before.
  - These are checked with the timing build on the watch (`docs/build.md`).
- **Pixels:** content drawn into a buffer can differ from the same drawing on the screen by a few levels along anti-aliased edges. This is accepted.

## Contour texture (Q43)

- **Lines:** topographic contour lines from the design's formula. Lines l = 1…40 have 64 points each, at r = 13·l·f(t) around (132, 318), with f(t) = 1 + 0.16 sin(3t + 0.6) + 0.08 sin(5t + 1.9) + 0.05 sin(7t + 0.3). Only lines 1–30 reach the background disc.
- **Pens and colors:** pen 2, every 5th line pen 3. Two colors only: C × 0.36 on C × 0.24.
- **Generation:** cut at build time by `tools/contourgen/generate.py` (`scripts/gen-contours.sh`), which reads the geometry from `source/Layout.mc`. Every piece stays:
  - at least half a pen inside r 194;
  - at least a pen plus 0.75 px outside every well rim, and outside the battery well (the arc band r 174–186 from −36° to +36°, with its r 6 caps).

  Pieces shorter than 3 px are dropped. The result is 93 pieces (404 segments), stored as packed numbers in `resources/contours/contours.json`. Run the generator again after any change to the wells, the rims or the disc.
- **Drawing:** plain flat-ended `drawLine` segments, so lines meet at mitred joins and the lines stop a few pixels short of each rim (design-sync). The texture is drawn in one go with the static layer: into the static buffer, and once on the screen with the first frame after a face start or a new face config.
- **AOD:** never drawn.

## Always On (AOD)

- **Content:** only the time and the date, at the same place and size as in high power, on black (Q12).
- **Time:** the same 86 px time font, filled, in C × 0.75 (Q13).
- **Date pill:** the same width as in high power, drawn as a 3 px outline. The pill is filled in the AOD color and its inside, inset by 3 px, is filled black again. The date text is one run in the AOD color.
- **Burn-in shift:** the time and date move together by one of 12 fixed offsets within ±4 px, offset (minute of the hour mod 12) (Q28):

  `(−4,−4) (1,−1) (4,4) (−4,−1) (−1,2) (4,−3) (−2,0) (1,3) (4,0) (−4,3) (−1,−4) (3,2)`

  Each step moves at least 3 px on both axes. No 3 consecutive offsets repeat or lie on one line, and minute 59 wraps to minute 0 on the cycle.
- **What AOD skips:** no buffers, sensors, seconds, ticks or texture. The AOD frame is recomputed only on a clock change.
- **Acceptance:** less than 10% of screen luminance, measured with the simulator heat map in low-power mode (Q35).

## Long press (Q5, Q45)

Touch and hold, in high power only. In AOD a hold does nothing.

| Target | Area |
|---|---|
| Left, center, right field | the field's well: circle R + 6 |
| Bottom field | the pill padded 10 px left, right and below and 4 px above: rounded rect (116, 332, 184, 54) with half-circle ends (radius 27), 4 px clear of the center field's target |
| Anything else (time band, date pill, battery bar, background, bezel ring) | no target |

The page opened belongs to the metric shown in the field held, not to the position. It is opened with `Complications.exitTo` for that metric's complication. A miss or a failed `exitTo` returns false, so the system handles the hold.

## Fonts

Bitmap fonts are generated by `tools/fontgen/generate.py` (`scripts/gen-fonts.sh`) from Big Shoulders and Manrope (SIL OFL 1.1, license files in `resources/fonts/`). The generator also writes `source/FontCatalog.mc`. That catalog has one entry per font with its resource, glyph set, glyph widths, base, cap height and letter spacing. FaceModel measures text through it and the renderer draws through it. Each font holds only the glyphs it draws (Q32).

| Font | Used for | Glyphs |
|---|---|---|
| Big Shoulders Display ExtraBold 86 | time, both modes | `0–9 :` |
| Manrope ExtraBold 17, 2 px letter spacing | date | `A–Z 0–9 /` and space |
| Manrope ExtraBold 48 | center field number | `0–9 -` |
| Manrope ExtraBold 26 | left/right numbers up to 3 characters, seconds | `0–9 -` |
| Manrope ExtraBold 22 | step number, left/right numbers of 4 characters | `0–9 . -` |
| Manrope ExtraBold 18 | step number shrunk, left/right numbers of 5 or more | `0–9 . -` |
| Manrope Bold 15 | `/ goal` | `0–9 . /` and space |
| Icons 24 | stress, bolt, heart, foot | U+E000–U+E003 |

All fonts are loaded once at startup. Garmin's system fonts are not used.

## Testing

- **One test seam: `FaceModel`**, pure logic with no sensor, graphics or resource dependency.
  - Tests call its entry points with a snapshot and a resolved face config: `compute`, `update`, `computeAod`, `updateAod`, `staticLayer`, `resolve`, `acceptedMetrics`, `readPlan`, `invalidated`, `everySecondParts`, `everyMinuteParts`, `minuteLayerChanged` and `longPressTarget`.
  - They check what would be drawn, read or hit. They never check private helpers.
- Tests are Monkey C `(:test)` functions, run in the simulator with `scripts/run-tests.sh`, which is authoritative.
- What the test files cover:

  | File | Covers |
  |---|---|
  | `tests/GoldenValues.mc` | pins every member of the default face's frames, static layer and long-press grid in the Mint theme (`TestConfigs.mintDefault`), so tests hold whichever theme the built-in config names. Re-record only for an intended change to what is drawn |
  | `tests/FrameEquality.mc` | checks that `update` equals `compute` over every frame member |
  | `tests/FieldMappingTest.mc` | a metric's look follows it to any accepted field |
  | `tests/FaceConfigTest.mc` | resolution and fallback |
  | `tests/RefreshPlanTest.mc` | read plans and invalidation |
  | `tests/SecondsTest.mc` | the seconds |
  | `tests/MinuteLayerTest.mc` | the minute-layer rule |
  | `tests/BezelRingTest.mc` | ticks and comet colors |
  | `tests/ThemeTest.mc` | all ten themes' derived colors against the design |
  | `tests/GlyphCoverageTest.mc` | every string any accepted config can print exists in its font |
  | `tests/ContourTest.mc` | every contour piece keeps its margins against the static layer's wells |

- Not unit-tested: the data reader, the renderer, the view and the delegate. These are checked by eye in the simulator against the design, with the AOD heat map, with the timing build for the cost limits, and on the watch.
