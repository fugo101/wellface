# Connect IQ platform findings for Wellface (FR265)

This document collects what the Connect IQ platform offers and requires for Wellface on the Forerunner 265 (device id `fr265`, Connect IQ API 5.2, round 416×416 AMOLED). It covers four areas: data sources, rendering and always-on display (AOD), interaction and localization, and tooling. Read it alongside `docs/decisions.md`, `GLOSSARY.md` and the final design in `design/claude-design/FR265 Watch Face.dc.html`.

**Sources and status**

- SDK pages are cited by path relative to the Connect IQ SDK 9.3.0 root, for example `doc/Toybox/Complications.html`.
- Device files are cited as `Devices/fr265/<file>` plus a key. The path is relative to the Connect IQ device folder that the SDK Manager maintains.
- Web sources are cited by URL. Forum posts are community reports. None of the cited posts came from Garmin staff.
- **CONFIRMED** means the fact was read in a primary source (SDK docs, samples, `bin/` files, device files, or the compiler bytecode in `bin/monkeybrains.jar`).
- **INFERRED** means the fact is reasoning, a synthesis, or a community report.
- Claims that the review refuted are left out. Claims that could not be verified are listed under [Open questions](#open-questions).

---

## Data sources

### Availability, permissions and update cadence

| Fact | Status | Source |
|---|---|---|
| The fr265 symbol table contains all of these: `SensorHistory.getBodyBatteryHistory/getStressHistory/getHeartRateHistory`, `ActivityMonitor.getHeartRateHistory`, `ActivityMonitor.Info.stressScore`, `INVALID_HR_SAMPLE`, `UserProfile.getHeartRateZones`, `HR_ZONE_SPORT_GENERIC`, `System.getSystemStats`, `Complications.getComplication/subscribeToUpdates/registerComplicationChangeCallback/exitTo`, and `COMPLICATION_TYPE_BODY_BATTERY/STRESS/HEART_RATE/STEPS`. | CONFIRMED | `Devices/fr265/fr265.api.debug.xml` (symbolTable) |
| `UserProfile.getHeartRateZones2` and `getCurrentSport2` (API 5.2.2) are **absent** on fr265. Part `006-B4257-00` reports `connectIQVersion` 5.2.0. | CONFIRMED | `Devices/fr265/fr265.api.debug.xml`; `Devices/fr265/compiler.json` `partNumbers[0].connectIQVersion` |
| The watch-face permission map allows `ComplicationSubscriber`, `SensorHistory` and `UserProfile`. ActivityMonitor and System need no permission. The Manifest page's table leaves the Watch Face cell empty for SensorHistory, which is a doc omission: `projectInfo.xml` is authoritative. | CONFIRMED | `bin/projectInfo.xml` `<permissionMap appType="watchface">`; `doc/Toybox/SensorHistory.html` and `doc/Toybox/UserProfile.html` ("Requires Permission"); `doc/docs/Core_Topics/Manifest_and_Permissions.html` |
| `App_Types.html` marks `Toybox.ActivityMonitor*` as "Requires app permission", but no ActivityMonitor permission exists anywhere. Treat this as a doc error. | CONFIRMED | `doc/docs/Connect_IQ_Basics/App_Types.html`; `bin/projectInfo.xml` |
| Subscribing to complications needs `ComplicationSubscriber`. No document says whether `getComplication` or `exitTo` work without it. | CONFIRMED / INFERRED | `doc/docs/Core_Topics/Complications.html` ("Subscribing to Complications") |
| The docs disagree on the minimum API for Complications. The module and every `COMPLICATION_TYPE_*` constant say 4.2.0, while `App_Types.html` and the Manifest table say 4.1.0. Use 4.2.0. | CONFIRMED | `doc/Toybox/Complications.html`; `doc/docs/Connect_IQ_Basics/App_Types.html`; `doc/docs/Core_Topics/Manifest_and_Permissions.html` |
| `Toybox.Activity` is **not** ticked for Watch Face in the module table, which warns of a "Symbol Not Found error". `getActivityInfo()` is described as being for apps and data-field initialization. On faces, community posts report `currentHeartRate` returning null on f5x, D2 Charlie, Descent Mk1 and Fenix 5, and working on a Venu 2. Nobody has tested it on fr265. | CONFIRMED (SDK) / INFERRED (forum) | `doc/docs/Connect_IQ_Basics/App_Types.html`; `doc/Toybox/Activity.html`; https://forums.garmin.com/developer/connect-iq/f/discussion/5977/how-to-get-current-hearth-rate-on-watch-faces/42285 |
| Watch faces mostly run in sleep mode, which allows one update per minute and no timers. `onExitSleep` raises the rate to one update per second until `onEnterSleep`. Faces cannot use the compass, GPS or other sensors (no `Toybox.Sensor`). | CONFIRMED | `doc/docs/Connect_IQ_Basics/App_Types.html` ("Watch Faces", "Watch Face Sleep") |
| The watch-face memory limit is 131072 bytes. The background limit is 65536 bytes. | CONFIRMED | `Devices/fr265/compiler.json` `appTypes`; `doc/docs/Device_Reference/fr265.html` |

### Metrics

| Metric / API | Fact | Status | Source |
|---|---|---|---|
| Body Battery, Complications | `COMPLICATION_TYPE_BODY_BATTERY` (23, API 4.2.0): "a Number representing your current body battery or null". `Complication.value` is `Complications.Value or Null` (String or numeric). `getComplication` throws `ComplicationNotFoundException`. | CONFIRMED | `doc/Toybox/Complications.html`; `doc/Toybox/Complications/Complication.html` |
| Body Battery, SensorHistory | `getBodyBatteryHistory` (API 3.3.0) returns an iterator, newest first by default. `{:period => 1}` returns only the newest sample. Range is 0–100. `SensorSample.data` can be null, and `next()` returns null when no samples remain. The doc says: "There are no guarantees on the sample interval", and the method has no access to synced data. | CONFIRMED | `doc/Toybox/SensorHistory.html`; `doc/Toybox/SensorHistory/SensorSample.html`; `doc/docs/Core_Topics/Quantifying_the_User.html` ("Sensor History") |
| Stress, three sources | (a) `getStressHistory` (API 3.3.0): stored samples 0–100, higher means more stress. (b) `ActivityMonitor.Info.stressScore` (API 5.0.0, fr265 listed): Number or Null, a rolling 30 s average. Scale: 0–25 resting, 26–50 low, 51–75 medium, 76–100 high. (c) `COMPLICATION_TYPE_STRESS` (22, API 4.2.0): "current stress level or null". The docs never mention negative values. | CONFIRMED | `doc/Toybox/SensorHistory.html`; `doc/Toybox/ActivityMonitor/Info.html`; `doc/Toybox/Complications.html` |
| Stress / Body Battery wording | The descriptions for HR, steps, battery and Pulse Ox say "non-negative". The STRESS and BODY_BATTERY descriptions do not. That makes a `< 0` guard reasonable for both. | CONFIRMED (wording) / INFERRED (behaviour) | `doc/Toybox/Complications.html` |
| Heart rate, Complications | `COMPLICATION_TYPE_HEART_RATE` (18, API 4.2.0): "a non-negative Number in beats per minute or null". | CONFIRMED | `doc/Toybox/Complications.html` |
| Heart rate, history | `ActivityMonitor.getHeartRateHistory` (API 1.2.1) returns `HeartRateSample` objects. Check `heartRate` against `INVALID_HR_SAMPLE` (255); both `heartRate` and `when` may be null. `SensorHistory.getHeartRateHistory` (API 2.1.0) has no 255 sentinel. Both cover data only "up to the last power cycle". The fr265 simulator stores HR history at 60 s intervals with 360 samples. Forum posts report real devices updating every 60–90 s. | CONFIRMED / INFERRED (real-device interval) | `doc/Toybox/ActivityMonitor.html`; `doc/Toybox/ActivityMonitor/HeartRateSample.html`; `doc/Toybox/SensorHistory.html`; `Devices/fr265/simulator.json` `sensorHistory`; forum thread 5977 (above) |
| Steps and goal | `ActivityMonitor.getInfo()` (API 1.0.0) needs no permission. `steps` is the "step count since midnight for the current day". `stepGoal` is "the step goal for the current day". Both may be null. Wheelchair mode returns zeroes for both. The docs do not mention Garmin's auto goal. | CONFIRMED (auto goal: INFERRED) | `doc/Toybox/ActivityMonitor/Info.html`; `doc/docs/Core_Topics/Quantifying_the_User.html` |
| Steps complication | In wheelchair mode, `COMPLICATION_TYPE_STEPS` is replaced by `COMPLICATION_TYPE_WHEELCHAIR_PUSHES`. SDK history records a fixed simulator exception when getting steps in wheelchair mode. | CONFIRMED | `doc/docs/Core_Topics/Complications.html`; `doc/docs/Readme/History.html` |
| Battery | `Stats.battery` is a non-nullable `Float` percentage (API 1.0.0). It may read slightly under 100 right after charging. `Stats.charging` is a Boolean (API 3.0.0). The Analog sample rounds with `(battery + 0.5).toNumber()`. | CONFIRMED | `doc/Toybox/System/Stats.html`; `samples/Analog/source/AnalogView.mc` |
| HR zones | `getHeartRateZones(sport)` (API 1.2.6, `UserProfile` permission) returns 6 values: min zone 1, then the max of zones 1 through 5. Garmin's example uses `HR_ZONE_SPORT_GENERIC` (0). Indices 0–4 are the five zone entry points; index 5 is the zone 5 maximum, not a threshold. The SDK does not say whether a zone's max belongs to that zone or the next one. | CONFIRMED (indexing) / INFERRED (boundary) | `doc/Toybox/UserProfile.html` |
| Complication extras | `Complication` also exposes `ranges` and `unit`. Their values for native types are not documented. | CONFIRMED (fields exist) | `doc/Toybox/Complications/Complication.html` |

### Polling vs subscribing

| Fact | Status | Source |
|---|---|---|
| `getComplication(id)` has no documented subscription precondition. The docs describe complications as "queried by identifier" and show a direct query. | INFERRED | `doc/Toybox/Complications.html`; `doc/docs/Core_Topics/Complications.html` |
| Garmin's reference face, ConfigurableWatchFace, **subscribes** and registers a change callback outside edit mode, and refreshes values only in that callback. It calls `getComplication` without subscribing only in edit mode, as a "snapshot". Polling without a subscription departs from the only Garmin sample. | CONFIRMED | `samples/ConfigurableWatchFace/source/ConfigurationWatchFaceView.mc` |
| `subscribeToUpdates` can throw `OperationNotAllowedException` "if too many active subscriptions". The limit is not documented. Subscriptions end when the app shuts down. | CONFIRMED | `doc/Toybox/Complications.html`; `doc/docs/Core_Topics/Complications.html` |
| Community reports: a subscribed callback fired every second even when the value had not changed (Venu 2). No callbacks arrive while a glance, widget or activity is in front. Nobody has measured the battery cost. | INFERRED | https://forums.garmin.com/developer/connect-iq/f/discussion/314641/complications-questions/1574292 ; https://forums.garmin.com/developer/connect-iq/f/discussion/333001/are-complications-only-received-when-the-watchface-derived-view-is-active |
| Community reports: the stress complication refreshes more often than `getStressHistory` (tested on an FR965). SensorHistory is saved "every 1-2 minutes at most". On a Venu 2, the HR complication and `ActivityInfo.currentHeartRate` matched, but the complication route used more resources in the simulator profiler. One developer saw `--` (null) for the Stress and Body Battery complications while Pulse Ox kept its last value. That this happened off-wrist was the poster's expectation, not something they observed. | INFERRED | https://forums.garmin.com/developer/connect-iq/f/discussion/355665/trade-offs-between-complication-value-versus-activitymonitor-sensorhistory-classes/1738228 ; https://forums.garmin.com/developer/connect-iq/f/discussion/367921/complication-value-updates |

### Simulator

| Fact | Status | Source |
|---|---|---|
| `fr265/simulator.json` has no `bodybattery` or `stress` entries under `sensorHistory`. fr970 has both, at 180 s intervals with 480 samples. Most devices that support Body Battery also lack these entries, and SDK history shows the simulator has simulated Body Battery and stress history for years ("Allow body battery and stress size to match the loaded device values"). A missing entry probably means default buffer sizes, not empty iterators. | CONFIRMED (files) / INFERRED (meaning) | `Devices/fr265/simulator.json` and `Devices/fr970/simulator.json` `sensorHistory`; `doc/docs/Readme/History.html` |
| The simulator supports native complications and has a complication viewer. A forum post says the simulator's Activity Data menu with Play feeds live data (menu names may differ slightly). | CONFIRMED (History) / INFERRED (menu) | `doc/docs/Readme/History.html`; forum thread 355665 (above) |

---

## Rendering & AOD

### Lifecycle and power modes

| Fact | Status | Source |
|---|---|---|
| The watch-face View lifecycle is `onLayout()` → `onShow()` → `onUpdate()`, with no `onHide()`. More than one `onUpdate()` may occur during view transitions. | CONFIRMED | `doc/Toybox/WatchUi/View.html` |
| In high-power mode (after a gesture, or when returning from another app, for "typically about ten seconds"), `onUpdate()` fires every second and timers are allowed. Then the system calls `onEnterSleep()`. | CONFIRMED | `doc/Toybox/WatchUi/WatchFace.html`; `doc/docs/User_Experience_Guidelines/Watch_Faces.html` |
| In low-power mode, `onUpdate()` fires at the top of every minute, with no timers. In AMOLED always-on mode the face "will only update every minute". | CONFIRMED | `doc/Toybox/WatchUi/WatchFace.html`; `doc/docs/User_Experience_Guidelines/Watch_Faces.html` ("Always On (AMOLED)") |
| `onEnterSleep` and `onExitSleep` have existed since API 1.0.0. The Analog sample keeps an `_isAwake` flag and calls `WatchUi.requestUpdate()` in `onEnterSleep`. | CONFIRMED | `doc/Toybox/WatchUi/WatchFace.html`; `samples/Analog/source/AnalogView.mc` |
| The `View.onUpdate` doc lists `requestUpdate()` as a trigger only for widgets and watch apps. Its effect in a watch face is undocumented. | CONFIRMED | `doc/Toybox/WatchUi/View.html` |
| `onPartialUpdate` is **absent** from the fr265 API file, while MIP devices (fr255, fr955, fenix7) have it. Per-second partial updates do not exist on fr265. The AMOLED FAQ also says they are "no longer allowed". | CONFIRMED | `Devices/fr265/fr265.api.debug.xml`; `doc/docs/Connect_IQ_FAQ/How_Do_I_Make_a_Watch_Face_for_AMOLED_Products.html` |
| `System.getDisplayMode()` (API 5.0.0, AMOLED and LCD only) returns `DISPLAY_MODE_HIGH_POWER` (0), `LOW_POWER` (1, "including watch face always-on mode… subject to burn-in protection") or `OFF` (2). `AppBase.onDisplayModeChanged()` (API 5.0.0) reports changes. Both are on fr265. | CONFIRMED | `doc/Toybox/System.html`; `doc/Toybox/Application/AppBase.html`; `Devices/fr265/fr265.api.debug.xml` |
| The AMOLED FAQ example has bugs: `System.getDisplayMode` is written without parentheses, and `requiresBurnInProtection` (a field) is called as a method. The missing `break` in that example is harmless. | CONFIRMED | `doc/docs/Connect_IQ_FAQ/How_Do_I_Make_a_Watch_Face_for_AMOLED_Products.html`; `doc/Toybox/System/DeviceSettings.html` |
| Community report (epix Gen 2): `onEnterSleep` was not called after a notification interrupted the face, and a face cannot tell it is in low power at startup until the first `onEnterSleep`. Another user reports the callbacks working correctly. | INFERRED | https://forums.garmin.com/developer/connect-iq/f/discussion/305577/onsleep-getting-missed-by-watchface |

### Burn-in rules

| Fact | Status | Source |
|---|---|---|
| `DeviceSettings.requiresBurnInProtection` (API 3.0.12, a field) states two rules: at most 10% of pixels on, and no pixel on for more than three once-per-minute cycles. If either is broken, the screen turns off until high power. | CONFIRMED | `doc/Toybox/System/DeviceSettings.html` |
| The AMOLED FAQ gives "10% on, no pixel on longer than 3 mins" as the original Venu rule, and says that "Since the Venu 2, the rule for always-on is to use less than 10% of the screen's luminance." | CONFIRMED | `doc/docs/Connect_IQ_FAQ/How_Do_I_Make_a_Watch_Face_for_AMOLED_Products.html` |
| SDK history entries: v4.1.0.beta1 relaxed the rules for Venu 2 and later. v4.1.1 restored the 3.x rules "for 3.x devices such as Venu and Venu Sq". v7.0.0.beta1 changed the general rule to "use total screen luminance rather than percentage of screen used". fr265 is a CIQ 5.2.0 device. | CONFIRMED | `doc/docs/Readme/History.html`; `Devices/fr265/compiler.json` |
| No document names the exact rule that fr265 enforces. The docs point to the luminance rule, which is less strict than the 3-minute rule in the repo's `CLAUDE.md`. | INFERRED | synthesis of the three rows above |
| A pixel counts as "on" for any colour other than black. Protection applies only when a CIQ face is in the foreground and the system is asleep. | CONFIRMED | AMOLED FAQ ("What Qualifies as Burn-In") |
| AOD guidelines: avoid much white or blue (light gray is better), use thin fonts, minimize static elements, and move elements "up to four pixels in any direction every minute". AMOLED faces are expected to support always-on. | CONFIRMED | `doc/docs/User_Experience_Guidelines/Watch_Faces.html` |
| Simulator: File → View Screen Heat Map opens a "Screen Burn-in Simulation" (24 h simulated in minutes). It is enabled only for faces on devices with screen protection, and fr265 has `screenProtectionSupport: true`. It shows pixel %, peak usage and luminance (SDK 6.4.0 and 7.0.0). Low power must be toggled by hand (since 3.1.7): Settings → Display Mode → Always-On in the SDK 9.3.0 simulator (ticket 11). The window shows Power Mode, Screen Protection, Burn-in State and Luminance Usage; the 24-Hour Simulation reports the peak luminance usage. | CONFIRMED | AMOLED FAQ ("How to Test…"); `Devices/fr265/simulator.json`; `doc/docs/Readme/History.html` |
| AOD is active only if the user turns it on: hold UP → System → Display → General Use / During Activity / During Sleep → Always On Display. With it off, the screen turns off after Timeout. | CONFIRMED | `doc/docs/User_Experience_Guidelines/Watch_Faces.html`; https://www8.garmin.com/manuals/webhelp/GUID-F41EAFB3-6CC9-42DE-9C6C-9E358DBB0671/EN-US/GUID-C9A5E731-8826-4AD0-8087-F6E2EAC625D6.html |

### Buffers and memory

| Fact | Status | Source |
|---|---|---|
| `Graphics.createBufferedBitmap(options)` (API 4.0.0) returns a reference. Options are `:width`, `:height`, `:palette` (up to 256 colours), `:colorDepth`, `:bitmapResource` and `:alphaBlending` (FULL is the default). `new BufferedBitmap()` is deprecated. `getDc()` has the same capabilities as the screen Dc. | CONFIRMED | `doc/Toybox/Graphics.html`; `doc/Toybox/Graphics/BufferedBitmap.html`; `doc/docs/Core_Topics/Graphics.html` |
| Since API 4.0, bitmaps, fonts and buffers live in a graphics pool separate from the app heap. The heap holds "code, data, stack and runtime objects". The fr265 simulator pool is 3,145,728 bytes. The pool is shared between apps. | CONFIRMED | `doc/docs/Core_Topics/Graphics.html`; `Devices/fr265/simulator.json` `graphicsResourcePoolSize`; `doc/docs/Readme/History.html` (v7.0.0.beta1) |
| A full-colour 416×416 buffer at 16 bpp is about 346,112 bytes (about 338 KB) of pool memory. That is a lower bound, because the extra cost of alpha under ALPHA_BLENDING_FULL is undocumented. **Measured (ticket 04):** in the fr265 simulator a default (ALPHA_BLENDING_FULL) 416×416 buffer takes 692,360 bytes of the pool (View Memory → Graphics Pool), that is 4 bytes per pixel plus 136 bytes, 22% of the 3,145,728-byte pool. A 2-bpp palette buffer is about 43 KB, but palette buffers forbid anti-aliasing and anti-aliased font text. | INFERRED (inputs CONFIRMED); the 4 bytes per pixel CONFIRMED in the simulator | `Devices/fr265/compiler.json` `bitsPerPixel`; `doc/Toybox/Graphics/Dc.html` |
| Purged buffers are **not restored** and must be re-rendered. Holding the `get()` result locks the buffer. `get()` can return null or throw `OutOfGraphicsMemoryException`. `isCached()` (API 4.0) reports whether the buffer was purged. SDK v7.2.0 fixed an error when drawing an evicted reference, which is another reason to keep the locked object. | CONFIRMED | `doc/docs/Core_Topics/Graphics.html`; `doc/Toybox/Graphics/ResourceReference.html`; `doc/Toybox/Graphics/BufferedBitmap.html`; `doc/docs/Readme/History.html` |
| The watch-face heap is 131072 bytes. Pool resources do not count toward it. Resource tables have a "minor runtime memory cost". `Stats.usedMemory/freeMemory` report heap use. `(:extendedCode)` (API 5.1.0) is shown only in a watch-app sample, so it is unverified for faces. | CONFIRMED | `Devices/fr265/compiler.json`; `doc/docs/Core_Topics/Resources.html`; `doc/Toybox/System/Stats.html`; `doc/docs/Monkey_C/Annotations.html`; `samples/ExtendedCodeSpace/manifest.xml` |

### Drawing primitives and fonts

| Fact | Status | Source |
|---|---|---|
| `drawArc(x, y, r, attr, start, end)`: 0° is 3 o'clock and 90° is 12 o'clock, so angles grow counter-clockwise. `attr` is `ARC_COUNTER_CLOCKWISE` (0) or `ARC_CLOCKWISE` (1). "All parameters are truncated towards zero", and equal start and end draws a **full circle**. How negative angles behave is undocumented. | CONFIRMED | `doc/Toybox/Graphics/Dc.html`; `doc/Toybox/Graphics.html` |
| `setPenWidth` is documented only as "the width of a line". A community post says the stroke is centred (on lines and circles, not arcs specifically). | INFERRED | `doc/Toybox/Graphics/Dc.html`; https://forums.garmin.com/developer/connect-iq/f/discussion/222926/draw-circle-or-arc-around-edge-of-round-device |
| The Dc API has no line-cap option. The full method list was checked. | CONFIRMED | `doc/Toybox/Graphics/Dc.html` |
| `fillRoundedRectangle` exists (API 1.0.0). `setAntiAlias` (API 3.2.0) is off by default and throws on palette buffers. From API 4.0: `setFill`/`setStroke` with 0xAARRGGBB, `setBlendMode` and `createColor`. `drawBitmap2` supports `:tintColor` and `:transform`. fr265 has `alphaBlendingSupport` and `enhancedGraphicSupport` set to true. The docs disagree on `drawBitmap2`'s API level (4.2.0, 4.2.1 or 4.2.2), which does not matter on 5.2. | CONFIRMED | `doc/Toybox/Graphics/Dc.html`; `doc/docs/Core_Topics/Graphics.html`; `Devices/fr265/compiler.json` |
| `drawText` takes its colour only from `setColor()`. Colours set with `setStroke`/`setFill` do not apply to text. | CONFIRMED | `doc/docs/Core_Topics/Graphics.html` (Drawing Context table) |
| Custom fonts are BMFont `.fnt` plus PNG pages. Resource attributes are `id`, `filename`, `filter`, `antialias` (default false, which gives 1-bit), `scope` and `personality`. Fonts have a single colour set by `setColor()`; two-colour effects need two stacked fonts. | CONFIRMED | `doc/docs/Core_Topics/Resources.html`; `bin/resources.xsd` `fontType`; `doc/docs/Connect_IQ_FAQ/How_Do_I_Use_Custom_Fonts.html` |
| Vector fonts (`getVectorFont`) cover only the device's system faces (Roboto family, Bionic Bold, Pridi, Noto/CJK). `drawAngledText` and `drawRadialText` reject custom fonts. TTF "resources" refer to system faces only. Big Shoulders Display and Manrope must ship as BMFont. | CONFIRMED | `doc/Toybox/Graphics.html`; `doc/docs/Core_Topics/Graphics.html`; `doc/docs/Device_Reference/fr265.html`; `bin/monkeybrains.jar` (`TTFont`) |
| Community bug report: `drawRadialText` and `drawAngledText` draw nothing into a buffer created with ALPHA_BLENDING_FULL on AMOLED. This matters only if vector text is ever drawn into a buffer. | INFERRED | https://forums.garmin.com/developer/connect-iq/i/bug-reports/drawradialtext-drawangledtext-fail-to-draw-to-bufferedbitmap-with-alpha_blending_full |
| Other fr265 display facts: `displayType` is amoled, `screenRotationSupport` is false, and `isTouch` is true. | CONFIRMED | `Devices/fr265/compiler.json`; `Devices/fr265/simulator.json` |

---

## Interaction & localization

### Long press

| Fact | Status | Source |
|---|---|---|
| `WatchFaceDelegate.onPress(clickEvent) as Boolean` (API 4.2.0) is "Called when user does a touch and hold". Return true when the event is handled. Forerunner 265 and 265s are listed. | CONFIRMED | `doc/Toybox/WatchUi/WatchFaceDelegate.html`; `Devices/fr265/fr265.api.debug.xml` |
| `onTap`, `getComplicationDrawable`, `setSelectedComplication` and `onWatchFaceConfigEdited` (API 5.1.0, config mode only) do **not** list the FR265. `onPress` is the face's only touch input. "A watch face can only know if it has been pressed." | CONFIRMED | `doc/Toybox/WatchUi/WatchFaceDelegate.html`; `doc/docs/Core_Topics/Input_Handling.html` |
| The delegate is registered by having `getInitialView()` return `[view, delegate]`, where the delegate extends `WatchUi.WatchFaceDelegate` and calls its `initialize()`. The Analog sample wraps this in a `WatchUi has :WatchFaceDelegate` guard and implements only `onPowerBudgetExceeded`. No SDK sample implements `onPress` or `exitTo`. | CONFIRMED | `doc/Toybox/Application/AppBase.html`; `samples/Analog/source/AnalogApp.mc`; `samples/Analog/source/AnalogView.mc` |
| `ClickEvent.getCoordinates()` returns `[x, y]` in pixels. `getType()` returns TAP (0), HOLD (1) or RELEASE (2). No document says which type `onPress` delivers. | CONFIRMED | `doc/Toybox/WatchUi/ClickEvent.html`; `doc/Toybox/WatchUi.html` |
| `Complications.exitTo(id)` (API 4.2.0, FR265 listed) "Launches the app associated with the complication". It throws `Lang.InvalidValueException`, but the Core Topic example catches `System.AppNotInstalledException`. Catch both, or `Lang.Exception`. | CONFIRMED | `doc/Toybox/Complications.html`; `doc/docs/Core_Topics/Complications.html` ("Hold to Launch"); `doc/Toybox/System/AppNotInstalledException.html` |
| Native Ids can be built directly with `new Complications.Id(COMPLICATION_TYPE_*)`; "This only works for native complications". The types are STEPS=2, HEART_RATE=18, STRESS=22, BODY_BATTERY=23 and WHEELCHAIR_PUSHES=40 (API 4.2.3). Nothing requires subscribing before calling `exitTo`. | CONFIRMED | `doc/Toybox/Complications.html`; `doc/Toybox/Complications/Id.html`; `doc/docs/Core_Topics/Complications.html` |
| No source names the screen that `exitTo` opens for each type. Forum reports say built-in complications such as Body Battery open their native glance or app. | INFERRED | https://forums.garmin.com/developer/connect-iq/i/bug-reports/issue-with-complications-exitto---exception-if-launching-an-app-widget ; https://forums.garmin.com/developer/connect-iq/f/discussion/407427/questions-regarding-onpress-and-complications-exitto-complicationid/1915663 |
| Community reports: `exitTo` to a CIQ widget complication failed on a Venu 2+ (firmware-related, later fixed), while built-in complications worked. One report says `onPress` does nothing when the face is reached from inside an activity; another says it works if touch is enabled for that activity. | INFERRED | the two forum URLs above |
| The FR265 has a touchscreen (Device Reference "Touch Screen: Yes", simulator `isTouch: true` with a `hold` gesture). Touch can be turned off per mode (hold UP → System → Touch), is unavailable during swims, and can be locked by Auto Lock. | CONFIRMED | `doc/docs/Device_Reference/Overview.html`; `Devices/fr265/simulator.json`; https://www8.garmin.com/manuals/webhelp/GUID-F41EAFB3-6CC9-42DE-9C6C-9E358DBB0671/EN-US/Forerunner_265_OM_EN-US.pdf |
| A face cannot read the user's touch setting. `isTouchScreen` reports only hardware support, and `configureTouchEvents` is limited to watch apps and audio content providers. | CONFIRMED | `doc/Toybox/System/DeviceSettings.html`; `doc/Toybox/WatchUi.html` |
| The FR265 customizes the watch face with hold UP, not a touch hold, so `onPress` should not clash with a system long-press. | CONFIRMED (manual) / INFERRED (no clash) | FR265 Owner's Manual (above) |
| Unhandled input: "Returning false will tell the system to handle the input." What the system then does with a hold on a face is undocumented. | CONFIRMED / INFERRED | `doc/docs/Core_Topics/Input_Handling.html` |
| SDK 8.3.0 added a "Toggle Touchscreen" setting to the simulator. A later fix mentions a "Complication launch view". How to trigger a hold with the mouse is undocumented. | CONFIRMED (History) / INFERRED | `doc/docs/Readme/History.html` |

### Date, time and language

| Fact | Status | Source |
|---|---|---|
| `Gregorian.info(..., FORMAT_MEDIUM).day_of_week` is an abbreviated String ("Sun" … "Sat"). FORMAT_LONG currently gives the same result. "The String values returned are language and device dependent." No Vietnamese form is documented. That the language follows System > Language is implied but not stated. | CONFIRMED (language link: INFERRED) | `doc/Toybox/Time/Gregorian/Info.html`; `doc/Toybox/Time.html` |
| Community reports: case differs between device and simulator (for example `SUN` on an Instinct 2 vs `Sun` in the simulator). Device strings can contain accented letters. The 2019 report that "the simulator does not localize" concerns simulator 3.0.10 and is not evidence about SDK 9.3.0. | INFERRED | https://forums.garmin.com/developer/connect-iq/i/bug-reports/capitalization-differs-between-simulator-and-device-when-using-gregorian-info ; https://forums.garmin.com/developer/connect-iq/i/bug-reports/gregorian-info-day_of_week-not-providing-localisation-for-most-languages-in-simulator ; https://forums.garmin.com/developer/connect-iq/f/discussion/377638/issue-with-rendering-spanish-unicode-literals-when-weekdays-is-mie |
| With FORMAT_SHORT, `day_of_week` is a Number from 1 (Sunday) to 7 (Saturday), matching `DAY_SUNDAY`…`DAY_SATURDAY` (API 3.0.0). `info.day` is a Number in every format. In FORMAT_MEDIUM, `month` is a localized String. | CONFIRMED | `doc/Toybox/Time/Gregorian/Info.html`; `doc/Toybox/Time/Gregorian.html` |
| `DeviceSettings.systemLanguage` (API 3.1.0) returns `LANGUAGE_*`, including `LANGUAGE_VIE`. The fr265 firmware ships 36 languages, including `vie` with fontSet `ww`. Resource folders accept the `vie` qualifier. | CONFIRMED | `doc/Toybox/System/DeviceSettings.html`; `doc/Toybox/System.html`; `Devices/fr265/compiler.json` `partNumbers[0].languages`; `doc/docs/Core_Topics/Resources.html` |
| A `Char` is a Unicode character, and `toNumber()` gives its code point. `String.toCharArray()`, `Number.toChar()` and `StringUtil.charArrayToString()` exist. `StringUtil` has no normalization. `toUpper()` behaviour for non-ASCII letters is undocumented. | CONFIRMED | `doc/Toybox/Lang/Char.html`; `doc/Toybox/Lang/String.html`; `doc/Toybox/Lang/Number.html`; `doc/Toybox/StringUtil.html` |
| `ClockTime.hour` always uses a 24-hour clock. `is24Hour` is only the user's preference. Q22 is met with `hour.format("%02d")` without reading `is24Hour`. | CONFIRMED | `doc/Toybox/System/ClockTime.html`; `doc/Toybox/System/DeviceSettings.html` |
| The fr265 system fonts (Roboto, fontSet `ww`) are used for Vietnamese, so native weekday text could be drawn with a system font instead. Whether every tone mark renders is untested. | CONFIRMED (fontSet) / INFERRED (rendering) | `doc/docs/Device_Reference/fr265.html`; `Devices/fr265/compiler.json` |
| UX guideline: "Leave enough space for translated text" and "Support multiple presentations of the date based on locale". | CONFIRMED | `doc/docs/User_Experience_Guidelines/Localization.html` |

---

## Tooling

### Project skeleton and manifest

| Fact | Status | Source |
|---|---|---|
| `bin/templates/watchface/simple` is the generated skeleton: a manifest with placeholders, a jungle containing only `project.manifest`, `App.mc` (AppBase), `View.mc` (WatchFace, which uses a layout plus `onShow`/`onHide`), `resources/layouts/layout.xml`, strings, drawables and a launcher SVG. | CONFIRMED | `bin/templates/watchface/simple/*` |
| Useful samples, with caveats: `samples/Analog` (BMFont font, `createBufferedBitmap`, WatchFaceDelegate; its manifest is the legacy version 1 format); `samples/ConfigurableWatchFace` (strict typecheck, ComplicationSubscriber; minApiLevel 5.1.0, uses WatchFaceConfig, fr265 not listed); `samples/TrueTypeFonts` (system vector fonts, lists fr265). | CONFIRMED | the sample folders named |
| Manifest attributes: `id` is a 128-bit UUID; `entry` names the AppBase class; `name` references a string resource and `launcherIcon` a bitmap resource (a default icon is used if omitted); only major.minor of `minApiLevel` affects device matching. | CONFIRMED | `doc/docs/Core_Topics/Manifest_and_Permissions.html` ("Application Attributes") |
| `onPress` and Complications need API 4.2.0. `docs/decisions.md` Q31 already fixes `minApiLevel` at 5.2. | CONFIRMED | `doc/Toybox/WatchUi/WatchFaceDelegate.html`; `doc/Toybox/Complications.html`; `docs/decisions.md` |

### Jungle, compiler and type checking

| Fact | Status | Source |
|---|---|---|
| Project qualifiers are `manifest`, `typecheck` and `optimization`. Device qualifiers include `sourcePath`, `resourcePath`, `excludeAnnotations`, `lang`, `barrelPath` and `personality`. Relative paths resolve against the jungle's folder. The default `sourcePath` includes **every** subfolder of the project, so set it explicitly. | CONFIRMED | `doc/docs/Reference_Guides/Jungle_Reference.html` |
| `monkeyc` flags: `-d` device, `-f` jungles (required), `-o` output (required), `-y` signing key (required), `-l 0..3`, `-w` warnings, `-t` include unit tests, `-r` release, `-O 0-3[p][z]`, `-e` .iq package, `--build-stats 0` byte usage, `-k` profile. `-g` prints compiler debug output only. | CONFIRMED | `doc/docs/Monkey_C/Compiler_Options.html`; `bin/monkeyc --help` |
| Type-check levels: 0 Silent, 1 Gradual, 2 Informative, 3 Strict. In SDK 9.3.0 the **default is Gradual** (History v4.1.6 and compiler bytecode; `Monkey_Types.html` is out of date). Precedence: CLI `-l` > jungle `project.typecheck` > default. The compiler warns only when the two differ. VS Code live errors need Gradual or higher. | CONFIRMED | `doc/docs/Monkey_C/Monkey_Types.html`; `doc/docs/Readme/History.html`; `bin/monkeybrains.jar` (`Monkeybrains`); `doc/docs/Reference_Guides/Visual_Studio_Code_Extension.html` |
| fr265 `codePageSize` is 4096 and `maxPrgFilespace` is 67108864. Code space is not the constraint; the 131072-byte runtime heap is. | CONFIRMED | `Devices/fr265/compiler.json` |

### Simulator and unit tests

| Fact | Status | Source |
|---|---|---|
| `connectiq` launches the simulator (`open -a ConnectIQ.app` on macOS). `monkeydo <prg> <device> [-t [names…]]` runs a build in an already running simulator. `monkeydo` is a Java wrapper, so `java` must be on PATH. | CONFIRMED | `doc/docs/Reference_Guides/Monkey_C_Command_Line_Setup.html`; `bin/connectiq`; `bin/monkeydo` |
| On macOS, the active-SDK pointer is `$HOME/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg`. The path contains a space and the value ends in `/`. `~/.Garmin/...` is the Linux location. | CONFIRMED | `doc/docs/Reference_Guides/Monkey_C_Command_Line_Setup.html` |
| Tests: build with `-t`, start `connectiq`, then run `monkeydo … -t`. Output shows per-test PASS/FAIL/ERROR, a `RESULTS` block, `Ran N tests` and a `PASSED`/`FAILED` summary. Each test runs independently. The docs show slightly different summary formats. | CONFIRMED | `doc/docs/Core_Topics/Unit_Testing.html`; `doc/Toybox/Test.html` |
| **`monkeydo -t` in SDK 9.3.0 exits 1 after every completed run, pass or fail.** It strips all `=` characters from the output and then matches a regex that requires `=`, so the PASSED flag is never set. Exit code 1 also means "Unable to communicate with the simulator". The v7.2.0 note "Return a non-zero exit code when unit tests fail" does not help here. | CONFIRMED | `bin/monkeybrains.jar` (`MonkeyDoDeux.messageReceived`, `execute`); `doc/docs/Readme/History.html` |
| No headless mode is documented. Run No Evil "operates only within the Connect IQ simulator", which is a GUI app. | CONFIRMED (no headless: INFERRED) | `doc/docs/Core_Topics/Unit_Testing.html`; `bin/connectiq` |
| Test API: `(:test) function name(logger as Test.Logger) as Boolean`. Non-global tests must be `static`. Available asserts are `assert`, `assertMessage`, `assertEqual(Message)` and `assertNotEqual(Message)`. A failing assert throws `AssertException`, which is reported as ERROR. Asserts in normal code run in debug builds and are compiled out of release builds. | CONFIRMED | `doc/Toybox/Test.html`; `doc/Toybox/Test/Logger.html`; `doc/docs/Core_Topics/Unit_Testing.html` |
| `(:test)` code is excluded unless built with `-t`. `(:debug)` and `(:release)` are excluded from the opposite build type. Un-annotated helpers in a test folder **are** compiled into the release PRG. | CONFIRMED (helper leak: INFERRED) | `doc/docs/Monkey_C/Annotations.html`; `doc/docs/Core_Topics/Unit_Testing.html` |

### Fonts and icons

| Fact | Status | Source |
|---|---|---|
| The compiler parses **text** `.fnt` files only, reading the `info`, `common`, `page`, `chars` and `char` tags. Kerning and `chnl` are ignored. Tokens are split on **single spaces**, and each must be exactly `key=value`; anything else fails with "is not a valid key/value pair". Glyphs with zero width trigger a "will not display" warning. | CONFIRMED | `bin/monkeybrains.jar` (`BMFont`, `BMFont$BMGlyph`); `doc/docs/Core_Topics/Resources.html` |
| The compiler reads glyph coverage as **RGB brightness**, ignoring alpha. The SDK's sample page is an 8-bit grayscale PNG. Write white-on-black 8-bit grayscale (`L`) pages. | CONFIRMED | `bin/monkeybrains.jar` (`GarminFontObject.convertToNBit`); `samples/Analog/resources/resource/fonts/blackdiamond_0.png`; `doc/docs/Connect_IQ_FAQ/How_Do_I_Use_Custom_Fonts.html` |
| An RGBA atlas that stores coverage only in alpha (white RGB everywhere) would likely lose anti-aliasing and render bold, jagged edges. | INFERRED | reasoning from the bytecode above |
| A font `filter` raises an error only if **none** of its characters exist in the font. Missing individual glyphs are dropped silently. Filters accept `\uXXXX` (BMP only) and the usual escapes. The SDK allows at most 4095 font resources and 2047 bitmap resources (v4.2.0.beta2). | CONFIRMED | `bin/monkeybrains.jar` (`GarminFontObject.readFont`, `getFilterCodepoints`); `doc/docs/Readme/History.html` |
| TTF support covers only references to system fonts. An arbitrary `.ttf` cannot be used. | CONFIRMED | `bin/monkeybrains.jar` (`TTFont`); `doc/docs/Readme/History.html` (v6.2.0) |
| Icons can be glyphs in a custom font, recoloured with `setColor`. The compiler stores 32-bit codepoints, so Private Use Area codepoints (U+E000…) should work, but rendering on the device is unverified. Monkey C string `\u` escapes are undocumented; use `(0xE000).toChar().toString()`. | CONFIRMED (compiler) / INFERRED (rendering) | `doc/docs/Connect_IQ_FAQ/How_Do_I_Use_Custom_Fonts.html`; `doc/Toybox/Lang/Number.html`; `bin/monkeybrains.jar` |
| `drawBitmap2` with `:tintColor` (FR265 listed) is an alternative way to recolour icons. Its blend semantics are undocumented. | CONFIRMED | `doc/Toybox/Graphics/Dc.html` |
| Generator tools: AngelCode BMFont runs on Windows only. fontbm has no macOS binary (it must be built with cmake and freetype). Its `--background-color 0,0,0` with the default white `--color` should produce RGB coverage, but it has no outline mode. Distance-field tools (msdf-bmfont-xml) are unsuitable. A Pillow script gives full control over the output. | CONFIRMED (fontbm options) / INFERRED (others) | https://github.com/vladimirgamalyan/fontbm |
| Homebrew's `pillow` bottle is built for specific Python versions, which may not match the `python3` first on PATH. A project venv is more reliable. | INFERRED | `brew info --json=v2 pillow` |

---

## Recommendations for Wellface

### Data sources

| Metric | Source | Fallback if needed |
|---|---|---|
| Body Battery | `Complications.getComplication(bbId).value` | `SensorHistory.getBodyBatteryHistory({:period => 1})` (needs the SensorHistory permission) |
| Stress | `Complications.getComplication(stressId).value` | `ActivityMonitor.getInfo().stressScore` |
| Heart rate | `Complications.getComplication(hrId).value` | `ActivityMonitor.getHeartRateHistory(1, true)`, filtering out `INVALID_HR_SAMPLE` |
| Steps / goal | `ActivityMonitor.getInfo().steps` and `.stepGoal` | – |
| Battery | `System.getSystemStats().battery` | – |
| HR zones | `UserProfile.getHeartRateZones(UserProfile.HR_ZONE_SPORT_GENERIC)` | – |

- **Permissions:** declare `ComplicationSubscriber` and `UserProfile`. Add `SensorHistory` only if a SensorHistory fallback is adopted.
- **Read cadence:** read the snapshot only when `System.getClockTime().min` changes, or in `onExitSleep`. Do not read on every high-power `onUpdate`, which fires every second. Skip all data reads in AOD.
- **Polling vs subscribing:** poll `getComplication` with no subscriptions. This departs from Garmin's sample, so first run a roughly 10-minute on-watch log (value plus time for each minute) to confirm the values refresh without a subscription. If they do not, use subscribe plus callback, or the per-metric fallbacks in the table. The FaceModel snapshot of nullable Numbers stays the same either way.
- **Complication handling:** create the Ids once in `initialize`. Wrap each `getComplication` in try/catch. Treat null, a non-Number value, or a value below 0 (for both stress and Body Battery) as missing: show `--` with the ring off (Q26). Hard-code 0–100 for the Body Battery and stress rings rather than relying on `ranges`.
- **Steps:** use ActivityMonitor, not the steps complication, which changes type in wheelchair mode. A null or 0 goal means an empty ring and no "/ goal".
- **Battery:** clamp lit segments to 0–10 after rounding. Keep the "all off" path only as a defensive branch.
- **HR zones:** use thresholds `zones[0..4]`. Apply the agreed rule from `docs/decisions.md`: lit = count of `zones[i] <= hr`. Lock it in a FaceModel test. Read the zones at start or in `onLayout`, and at most again in `onExitSleep`.

### Rendering and AOD

- **Mode detection:** use `System.getDisplayMode()` in every `onUpdate` as the source of truth. Use `onEnterSleep`/`onExitSleep` only to request a redraw. Return early on `DISPLAY_MODE_OFF`. Do not implement `onPartialUpdate` (it does not exist on fr265).
- **Static layer:** render the background, wells, tracks and off segments once (the notches go in the dynamic pass, after the bezel progress arc, or the arc would cover them) into a full-colour BufferedBitmap and keep the locked `get()` result. If it is null or `!isCached()`, re-render it.
- **Dynamic layer:** draw the dynamic parts once per minute. Optionally cache the finished frame in a second buffer, so a per-second high-power update is a single `drawBitmap`. Measure the pool cost first; each full-colour buffer takes about 676 KB in the simulator (ticket 04).
- **AOD:** use no buffers. Clear to black and draw only the outline time and date, in accent × 0.55, at FaceModel's ±4 px per-minute offset (Q12, Q13, Q17, Q28). Design to satisfy both the 10% / 3-minute rule and the luminance rule, and check with the heat map in low-power mode.
- **Arc geometry in FaceModel:**
  - Emit integer angles normalized to 0–359.
  - Never emit a zero sweep, because start == end draws a full circle.
  - Expect the battery's 1.6° gaps to become whole degrees.
  - Add round caps with `fillCircle` at the arc ends.
  - Check pen-width centring at r=204 in the simulator.
- **Fonts:** ship Big Shoulders Display and Manrope as BMFont fonts with `filter` subsets and `antialias="true"`, coloured with `setColor`.

### Interaction and localization

- **Delegate:** `getInitialView()` returns `[view, new WellfaceDelegate()]`.
- **onPress:** get the coordinates, call `FaceModel.hitTest(x, y)`, return false on a miss, otherwise call `Complications.exitTo(idForMetric)` inside a try/catch that catches `Lang.Exception`. Do not branch on `getType()`. The metric picks the target, not the field (Q29).
- **Hit test:** use the circle geometry from `docs/decisions.md` padded by 6 px (the well) with a squared-distance test, and an unpadded rounded-rect test for the steps pill (the pill is its own well). The Body Battery well and the steps pill are 8 px apart.
- **Date:** build the date string in FaceModel. Map the FORMAT_MEDIUM weekday code point by code point to A–Z:
  - fold Vietnamese and Latin accented letters to their base letter, using compact lookup strings;
  - drop combining marks;
  - fall back to an English abbreviation from the FORMAT_SHORT number for any other script.

  Do not rely on `toUpper()` or the device's capitalization. Unit-test English, Vietnamese (precomposed and combining), Cyrillic and the empty string.
- **Space glyph:** the Manrope glyph list in `docs/decisions.md` has no space, but "THU 12" needs one. Either add U+0020 to the font or draw the weekday and day with two `drawText` calls. This needs a decision.
- **Time:** use `ClockTime.hour`/`min` with `%02d` and ignore `is24Hour` (Q22).

### Tooling

- **Skeleton:** start from `bin/templates/watchface/simple` without the layout. Borrow code patterns from `samples/Analog` and `samples/ConfigurableWatchFace`, but not their manifests.
- **Manifest:** `type="watchface"`, a fresh UUID, `minApiLevel="5.2.0"`, product `fr265`.
- **`monkey.jungle`:** `project.manifest = manifest.xml`, `project.typecheck = strict` (the single source of truth, so omit `-l`), `base.sourcePath = source;tests`, `base.resourcePath = resources`.
- **Test code:** every function and class in `tests/` is `(:test)`.
- **Scripts:**
  - `SDK="$(cat "$HOME/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg")"; SDK="${SDK%/}"`
  - Debug: `"$SDK/bin/monkeyc" -d fr265 -f monkey.jungle -o bin/wellface.prg -y "$CIQ_DEV_KEY" -w`. The key path comes from an environment variable and is never stored in the repo.
  - Tests: the same command plus `-t -o bin/wellface-test.prg`, then `connectiq`, then `monkeydo bin/wellface-test.prg fr265 -t > bin/test.log 2>&1`.
  - A test run passes only if the log has a line starting with `PASSED`, no line starting with `FAILED`, and `Ran N` with N > 0. Ignore `monkeydo`'s exit code. A missing `RESULTS` block is an infrastructure error.
  - Sideload build: add `-r --build-stats 0` (and `-O 2z` if needed), then copy the `.prg` to `GARMIN/APPS`.
- **Fonts:** commit `tools/fonts/make_fonts.py` (Python with Pillow, in a gitignored venv with pinned `requirements.txt`; installing it needs the user's OK). It should:
  - write a text `.fnt` with single spaces only;
  - write one 8-bit grayscale page per font, white on black;
  - build the AOD outline as the fill minus a 2 px erosion;
  - put icons at PUA codepoints;
  - **fail if any requested glyph is missing**, because the compiler will not.

---

## Open questions

**Data**
1. Does `getComplication(id).value` refresh every minute on the FR265 without a subscription? Test with a 10-minute log against the native widgets. **Answered (ticket 02, on the watch, 2026-11-12): yes.** Over about 17 minutes, BB changed twice and stress 28 times, at minute polls too (including in low power), and the values followed the watch widgets. While awake, heart rate changed every 2.7 s on average (often every second).
2. Does the fr265 simulator return Body Battery and stress history, and does it supply complication values? Check with a one-line `println`, the complication viewer, and the Activity Data menu (menu names may differ slightly). **Partly answered (ticket 02, SDK 9.3.0, 2026-11-12):** the simulator supplies complication values without any setup: Body Battery and stress jumped to new values at each minute poll (57 → 28, 25 → 78), so they are simulated, not a fixed value; heart rate changed on 47 of 48 per-second polls. Steps read 0 with goal 5000 and the generic zones `[93, 111, 130, 148, 167, 185]`. History was not checked.
3. Does `Activity.getActivityInfo().currentHeartRate` work on an fr265 face? This matters only if the HR complication proves stale.
4. Which on-watch zone set does `HR_ZONE_SPORT_GENERIC` return (Default or Running zones)? Does the watch's own display treat a zone's max bpm as inclusive? **Answered (ticket 02, on the watch):** it returns the zones the watch shows. The watch shows % of max HR (50/60/70/80/90/100% of 192), and the API returns them rounded to the nearest bpm: `[96, 115, 134, 154, 173, 192]`. Inclusivity of a boundary cannot be read from the % display; the spec counts a bound as the higher zone. **On the face (ticket 13, 2026-11-13, user report):** the lit zone segments match the zones the watch itself shows, so `HR_ZONE_SPORT_GENERIC` gives the zones the user sees. Which named zone set that is was not checked.
5. Does `stepGoal` follow Garmin's daily auto goal? Compare with the Steps widget. **Likely yes (ticket 02):** `stepGoal` read 3,110, the day's auto goal (about 3,100). **Confirmed (ticket 13, 2026-11-13, user report):** the goal in the bottom field matches the Steps widget.
6. Do the stress or Body Battery complications ever return negative values? **Not seen (ticket 02):** no negative, null or non-Number value in about 17 minutes. Not proof that it never happens, so FaceModel still treats negatives as missing.
7. What is the limit on active complication subscriptions? This does not matter if polling works. **Moot (ticket 02):** polling works, so the face never subscribes.
8. Does `getComplication` or `exitTo` require the `ComplicationSubscriber` permission? Declared anyway. **Answered for `getComplication` (ticket 02):** yes. Without the permission the compiler fails with "Permission 'ComplicationSubscriber' required for '$.Toybox.Complications.getComplication'" and "Permission 'ComplicationPublisher' or 'ComplicationSubscriber' required for '...Complication.value'". **Answered for `exitTo` (ticket 12):** yes. Without the permission the compiler fails with "Permission 'ComplicationSubscriber' required for '$.Toybox.Complications.exitTo'", and building an `Id` or naming a `COMPLICATION_TYPE_*` needs `ComplicationPublisher` or `ComplicationSubscriber`.

**Rendering & AOD**

9. Does the fr265 firmware enforce the 3-minute per-pixel rule, or only the luminance rule? Check with the heat map and on the watch with Always On enabled. **Partly answered (ticket 13, 2026-11-13, user report):** with this face (peak luminance 0.60% in the simulator, shifting each minute) the FR265 never turned the screen off during normal wear. Which rule the firmware enforces is still unknown.
10. The repo `CLAUDE.md` states "each pixel lit ≤ 3 minutes" as fact for the FR265. Current SDK docs describe a luminance-based rule for post-Venu 2 devices. Should the wording be softened? Ask the user before editing.
11. Is the `drawArc` stroke centred on r? How are negative angles handled?
12. Does a 416×416 buffer with ALPHA_BLENDING_FULL cost 2 or 4 bytes per pixel? Is the second "frame" buffer worth it? **Answered in the simulator (ticket 04):** 4 bytes per pixel (692,360 bytes). Not yet checked on the watch. Whether a second buffer is worth it stays open.
13. Does `onUpdate` still fire every minute when the display is `DISPLAY_MODE_OFF` (Always On disabled)? Does `getDisplayMode()` actually report OFF in that state?
14. Does `requestUpdate()` trigger an immediate `onUpdate` in a watch face?
15. Does `(:extendedCode)` work for watch faces? Probably not needed for the MVP.
16. What is the exact name of the simulator's low-power menu (likely Settings → Low Power Mode)? Menu names may differ slightly. **Answered (ticket 11, SDK 9.3.0): Settings → Display Mode → Always-On.**

**Interaction & localization**

17. Which screen does `exitTo` open on the FR265 for BODY_BATTERY, STRESS, HEART_RATE and STEPS? **Answered (ticket 12, on the watch, 2026-11-13, user report):** each opens the matching Garmin page; the exact page names were not noted.
18. What does the FR265 return for the FORMAT_MEDIUM weekday in Vietnamese: which form ("T2", "Th 2", …), which case, and precomposed or combining diacritics? Check on the watch. **Answered for Thursday (ticket 02, on the watch, 2026-11-12):** `"Thứ 5"`, code points `54 68 1EE9 20 35`: title case, the `ứ` is precomposed (U+1EE9), and the name contains a space and an ASCII digit. Other weekdays, Sunday especially, are not observed yet. **Friday on the face (ticket 13, 2026-11-13, user report):** with the watch in Vietnamese the date pill showed the weekday correctly.
19. Does `onPress` fire in AOD or low power, or only after the screen wakes? Does it fire when the face is shown from inside an activity? **Partly answered (ticket 12, simulator only):** in the simulator's Always-On mode a hold still calls `onPress`, with `getDisplayMode()` reporting low power, so the face's own high-power check is what makes holds do nothing in AOD. **On the watch (ticket 12, 2026-11-13, user report):** the first touch in Always On wakes the screen; a hold that continues then reaches `onPress` in high power and opens the page, and a short hold only wakes the screen. The activity case is not checked yet.
20. Does returning false from `onPress` trigger any system action on the FR265? **Simulator (ticket 12):** nothing visible happens. Not checked on the watch.
21. How do you trigger a hold gesture with the mouse in the simulator? **Answered (ticket 12, SDK 9.3.0):** press and hold the left mouse button on the screen (1.5 s worked). `onPress` gets `getType()` HOLD (1) and the exact screen coordinates. The simulator then shows a plain launch view, for example "Body Battery launched", instead of a Garmin page; File → Kill App and reloading the face brings the face back.

**Tooling**

22. Do the Google Fonts downloads of Big Shoulders Display and Manrope include static ExtraBold/Bold TTFs, or must they be instantiated from the variable font (for example with fontTools)? **Answered (ticket 03, 2026-11-12):** google/fonts publishes no static files for either. `ofl/bigshouldersdisplay` holds only `BigShouldersDisplay[wght].ttf`, which its `config.yaml` builds as the opsz=72 subspace of "Big Shoulders" (from an older upstream commit); `ofl/manrope` holds only `Manrope[wght].ttf`. The generator instances the variable fonts with fontTools.
23. Install Pillow in a gitignored venv? This needs the user's approval. **Answered (ticket 03, 2026-11-12):** approved; `.venv/` with Python 3.15, Pillow 13.0.0 and fontTools 4.68.0, created by `scripts/gen-fonts.sh`.
24. Do PUA-codepoint glyphs render on the fr265 simulator and device? Test with a one-glyph font. **Simulator: yes (ticket 07, SDK 9.3.0, 2026-11-13).** The bolt at U+E000 in the generated icon font (filter `\uE000`, drawn with `drawText` from `(0xE000).toChar().toString()`) renders in the right place and takes the `setColor` color. **Device: yes (ticket 07, 2026-11-13, user report).** The bolt shows on the FR265 in the warning color. **All four icons (stress, bolt, heart, foot) render correctly on the FR265 (ticket 13, 2026-11-13, user report).**
25. Do the anti-aliased fonts and the 2 px outline AOD time stay within the burn-in budget? Check with the heat map.
26. What are the semantics of `drawBitmap2` `:tintColor` (multiply or replace)? This matters only if bitmap icons are preferred over an icon font.
27. Confirm on the first test run that `monkeydo -t` really exits 1 even when all tests pass.