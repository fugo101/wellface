# CI and distribution findings for Wellface

This document collects what was checked about running Connect IQ builds in GitHub Actions, what the Connect IQ developer agreement allows, how a watch face can support more than one device, and how to distribute builds outside the Connect IQ Store. It was verified on 2026-11-26. Read it with `docs/research/connect-iq-platform.md` (platform facts) and `.github/workflows/` (the result).

**Sources and status**

- Web sources are cited by URL. Forum posts and third-party repositories are community reports, not Garmin statements.
- **CONFIRMED** means the fact was read in a primary source (Garmin's pages, a project's source code, a tool's own `--help` output, or a file that was downloaded and hashed).
- **INFERRED** means the fact is reasoning, a reading of a license text, or a community report. None of this is legal advice.
- Questions that could not be answered are listed under [Open questions](#open-questions).

---

## What CI can check

Every option below, even a compile-only build, needs the device files for the target device. They come only from Garmin's SDK Manager API, which needs a Garmin login, or from a third party that republished them.

| Fact | Status | Source |
|---|---|---|
| The SDK for Linux is a plain zip that downloads without a login. The pinned one is `connectiq-sdk-lin-9.3.0-2026-10-20-95888f262.zip` (215,470,376 bytes, SHA-256 `1653cc98edd70029670a3e3fcd4ad6e746974a8b758a7b736a4e11506dfd8bc8`, computed from a fresh download). It unpacks with `bin/` (containing `monkeyc`, `monkeydo` and `connectiq`) and `doc/` at its root. | CONFIRMED | https://developer.garmin.com/downloads/connect-iq/sdks/connectiq-sdk-lin-9.3.0-2026-10-20-95888f262.zip |
| Garmin keeps an index of all SDK releases, with the file names per platform, at a fixed URL. | CONFIRMED | https://developer.garmin.com/downloads/connect-iq/sdks/sdks.json |
| The "Accept & Download" links on the SDK page fetch the **SDK Manager** (a GUI), not the SDK zip. | CONFIRMED | https://developer.garmin.com/connect-iq/sdk/ |
| `lindell/connect-iq-sdk-manager-cli` (Apache-2.0, unofficial) downloads SDKs, devices and fonts through Garmin's SDK Manager API. Its last release is v0.8.4 (2026-02-22); the Linux x86-64 archive has SHA-256 `5d57b8f9cfcd02d3b3f48e19d6daca0480e4c6f627926f15d8617ef8a6f57e0b` (from the release's `checksums.txt`, and the same when computed from the download). | CONFIRMED | https://github.com/lindell/connect-iq-sdk-manager-cli/releases/tag/v0.8.4 |
| The CLI's commands (v0.8.4 `--help`): `agreement view`, `agreement accept`, `login`, `device download`, `device list`, `sdk download`, `sdk set`, `sdk current-path`. `device download` takes `--manifest <manifest.xml>`, `--device <id>` or `--download-all`, and `--include-fonts`. | CONFIRMED | `connect-iq-sdk-manager <command> --help`; https://github.com/lindell/connect-iq-sdk-manager-cli |
| `agreement accept` takes `--agreement-hash` (`-H`), the hash of a previously read agreement. The CLI's README calls the flag `--acceptance-hash`, which is wrong for v0.8.4. The value is an MD5. | CONFIRMED | https://raw.githubusercontent.com/lindell/connect-iq-sdk-manager-cli/v0.8.4/cmd/cmd-agreement-accept.go ; `agreement accept --help` |
| `agreement view` needs no login. It prints the agreement's URL and its current hash (2026-11-26: `CC737BBBA104D7740D5BBCF27D0F6382`). The hash changes when Garmin changes the agreement. | CONFIRMED | `connect-iq-sdk-manager agreement view`; https://raw.githubusercontent.com/lindell/connect-iq-sdk-manager-cli/v0.8.4/cmd/cmd-agreement-view.go (`SkipLoginRequired: true`) |
| `login` reads `GARMIN_USERNAME` and `GARMIN_PASSWORD` from the environment (or `--username` / `--password`). With no credentials it starts the Garmin SSO OAuth flow in a browser. | CONFIRMED | `connect-iq-sdk-manager login --help` |
| On Linux the CLI keeps its files under `~/.Garmin/ConnectIQ/`: `Sdks/`, `Fonts/`, `Devices/`, `current-sdk.cfg`, `sdkmanager-config.ini`, and the login token as `token.json`. This is also where `monkeyc` looks for devices on Linux, and where `scripts/common.sh` looks for `current-sdk.cfg`. | CONFIRMED (CLI) / INFERRED (monkeyc) | https://raw.githubusercontent.com/lindell/connect-iq-sdk-manager-cli/v0.8.4/internal/connectiq/fs.go ; https://raw.githubusercontent.com/lindell/connect-iq-sdk-manager-cli/v0.8.4/internal/storage/storage.go |
| Which CLI commands need a login is not documented ("some parts of the manager"). Downloading devices is assumed to need one. | INFERRED | https://github.com/lindell/connect-iq-sdk-manager-cli |
| `ubuntu:22.04` is the distribution that works. On Ubuntu 24.04 the simulator fails with `libwebkit2gtk-4.0.so.37: cannot open shared object file`; Garmin's bug report has been "Acknowledged" since 2024-05-06 with no fix version. A compile-only build does not start the simulator, and a forum reply says that for builds alone a headless machine should be fine. | CONFIRMED (bug report) / INFERRED (compile-only) | https://forums.garmin.com/developer/connect-iq/i/bug-reports/ubuntu-24-04-support ; https://forums.garmin.com/developer/connect-iq/f/discussion/400071/help-with-github-actions-for-building-and-testing-garmin-applications |
| GitHub deprecated the hosted `ubuntu-22.04` runner image on 2026-09-17 and retires it on 2027-04-17. A job that needs 22.04 therefore runs an `ubuntu:22.04` container on `ubuntu-latest`. | CONFIRMED | https://github.com/actions/runner-images/issues/14254 |
| A container pinned by tag and digest is what an existing project uses for its Connect IQ CI (`ubuntu:22.04`, SDK 9.3.0, device files downloaded each run, credentials from a dedicated account, token deleted on exit). | CONFIRMED | https://github.com/stefiix92/coachd/pull/31 ; https://raw.githubusercontent.com/stefiix92/coachd/main/watch/ci-setup.sh |
| `monkeydo -t` (run unit tests in the simulator) exits 1 even when every test passes, so pass/fail must come from the output. `--unit-test --release` is rejected: "Unable to build unit tests in release mode." | CONFIRMED | https://raw.githubusercontent.com/matco/connectiq-tester/master/tester.sh ; https://github.com/openhab/openhab-garmin/pull/401 |
| `matco/connectiq-tester` (a Docker image with the SDK, device files and a simulator under Xvfb) runs compile and unit tests without any secrets. It republishes Garmin's device files in a public image; its README itself calls them "the property of Garmin". | CONFIRMED | https://github.com/matco/connectiq-tester |
| Public examples of the simulator under Xvfb cover fenix 7, fr55, fr245, fenix 6 Pro and Venu 2. None covers the Forerunner 265. | CONFIRMED (that none was found) | the repositories above |
| GitHub-hosted standard runners are free in public repositories. | CONFIRMED | https://docs.github.com/en/billing/concepts/product-billing/github-actions |

### Options, ranked

| Rank | Option | What it checks | Needs | Risk |
|---|---|---|---|---|
| 1 | Compile-only job, device files fetched fresh each run | Type errors, unresolved symbols and per-device resource errors, for every device in `manifest.xml`, with warnings as errors. No test results. | A dedicated Garmin account without 2FA (secrets), a throwaway key made in the job | The CLI is unofficial and can break when Garmin changes its login. The job must skip cleanly without the secrets, and fork pull requests never get them |
| 2 | Full test job: compile plus `(:test)` run in the simulator under Xvfb | Everything above plus the unit tests | The same, plus a packages list for the simulator | The Forerunner 265 under Xvfb is not demonstrated anywhere. Simulator hangs need a timeout and a retry |
| 3 | A third-party image such as `matco/connectiq-tester` | Compile and tests | No secrets | Republishes Garmin's files (see Licensing), one maintainer, no confirmation that the image has `fr265` |
| 4 | A macOS hosted runner with the native simulator | Compile and tests | The same secrets | No public working example; GUI behaviour on hosted runners is not verified |

Decision: option 1 runs in `.github/workflows/build.yml`. Option 2 is a later experiment; until then `scripts/run-tests.sh` on a developer's machine is the authoritative test run.

---

## Licensing

Source: the Connect IQ developer agreement, updated 2024-08-06, https://developer.garmin.com/downloads/connect-iq/sdks/agreement.html (quotes read on 2026-11-26).

| Clause | Text | Status |
|---|---|---|
| I.a | The license is "for the sole purpose of developing and testing Applications". | CONFIRMED |
| I.b | You may not "upload to or host on any website or server, sell, redistribute, or sublicense the Program Materials", nor "copy (except as expressly permitted ...)". | CONFIRMED |
| IX.p | Program Materials are "any materials made available to you by Garmin or a Garmin affiliate in connection with the Garmin Developer Program". That reads as covering device files and Garmin's fonts as well as the SDK. | CONFIRMED (text) / INFERRED (scope) |
| IV.d, IX.f | The SDK and Program Materials are Confidential Information, not to be disclosed to third parties. | CONFIRMED |
| II.a | Garmin is the developer's agent for the Connect IQ Store. The agreement says nothing about sideloading, open source or distribution outside the Store. | CONFIRMED |

What this means for the project (a reading, not legal advice; INFERRED):

| Action | Assessment |
|---|---|
| Commit the SDK, device files or Garmin fonts to the public repository | Not permitted (I.b, IV.d). The repository never contains them |
| Publish a public Docker image or artifact that contains them | Not permitted. Third-party images that do are not used |
| Download them from Garmin in each CI run | Fits the "developing and testing" grant. This is what `build.yml` does |
| `actions/cache` of `Devices/` or `Fonts/` | A grey zone ("host on any ... server"): the cache is private but sits on GitHub's servers. The job does not cache, at the cost of one login per run |
| Publish the project's own source | Not restricted. The project's code is not Program Materials |
| A throwaway signing key made in CI | Nothing in the agreement forbids it |
| Bitmap fonts generated from Big Shoulders and Manrope (SIL OFL 1.1), kept in `resources/fonts/` | Not Garmin material. Their OFL license files are in that folder |

---

## Multi-device support

| Fact | Status | Source |
|---|---|---|
| Supported devices are the `<iq:product>` entries of `manifest.xml`. A device's `.prg` is built with `monkeyc -d <device>`. | CONFIRMED | https://raw.githubusercontent.com/ludw/Segment34/main/manifest.xml |
| The SDK's `bin/default.jungle` (marked "FOR REFERENCE ONLY"; read in the macOS SDK 9.3.0, not checked in the Linux zip) sets `base.resourcePath = resources`, defines family qualifiers such as `round-360x360` that append `resources-round-360x360`, and per-device entries that append `resources-<device>`, for example `fr265s.resourcePath = $(fr265s.resourcePath);resources-fr265s`. | CONFIRMED | `bin/default.jungle` of the macOS SDK 9.3.0 |
| Device files: `fr265` is `deviceFamily` `round-416x416`, AMOLED. `fr265s` is `round-360x360`, AMOLED. | CONFIRMED | `Devices/fr265/compiler.json`, `Devices/fr265s/compiler.json` |
| A jungle can override per device or per family, and the override appends to the inherited list. Crystal Face does this (`fr245.resourcePath = $(fr245.resourcePath);resources-no_floors`, `base.excludeAnnotations = ...`). | CONFIRMED | https://raw.githubusercontent.com/warmsound/crystal-face/master/monkey.jungle |
| `excludeAnnotations` removes annotated code per device. It does not select resource folders. | INFERRED | https://forums.garmin.com/developer/connect-iq/f/discussion/247716/using-excludeannotations-in-monkey-jungle-for-onlayout-dc |
| Neither Crystal Face nor Segment34 has a contributing guide or a documented way for owners of other watches to add their own device. | CONFIRMED | https://api.github.com/repos/warmsound/crystal-face/contents ; https://api.github.com/repos/ludw/Segment34/contents |

Design proposal (not a platform fact): ship only `fr265`; keep every device-specific value (coordinates, fonts, the generated contour table, golden values) in per-device resources or a per-device layout, so a new size is purely additive; a porter adds the manifest entry and those files and proves the port on a real watch; CI compiles every manifest device. The project's rules for ports are in `CONTRIBUTING.md`.

---

## Distribution through GitHub Releases

| Fact | Status | Source |
|---|---|---|
| The developer agreement neither allows nor forbids distributing a compiled app outside the Store. A Garmin wiki page says developers "may still continue to build and distribute these apps as you wish outside of the Connect IQ app store", in the context of medical-app exceptions. | CONFIRMED (text) / INFERRED (reach) | https://forums.garmin.com/developer/connect-iq/w/wiki/10/app-approval-exceptions |
| Segment34 commits a pre-built `.prg` per device under `build/<device>/` and tells users to copy it to `GARMIN/Apps`. It has no GitHub Releases. No public Connect IQ face using Releases assets was found. | CONFIRMED | https://raw.githubusercontent.com/ludw/Segment34/main/README.md ; https://api.github.com/repos/ludw/Segment34/contents/build |
| A `.prg` is built for one device, so a release carries one asset per supported device (`wellface-<device>.prg`). | CONFIRMED | `monkeyc -d` |
| A release build needs a developer key. The project builds releases on the maintainer's machine with the real key (`scripts/release.sh <semver>`); the key never goes to CI. | decision | n/a |
| Two builds of the same source with the same SDK and key gave the same PRG (same SHA-256), so a release's checksums can be reproduced on the same machine. | CONFIRMED (one device, one machine) | `scripts/release.sh`, run twice |
| On newer watches, forum reports say sideloaded PRGs move into hidden storage, the phone app cannot uninstall them, and a name mismatch between `.set` and `.prg` causes problems. Release notes therefore carry install and uninstall steps. | INFERRED | https://forums.garmin.com/developer/connect-iq/f/discussion/367718/sideload-prg-file-no-longer-working |

---

## Open questions

1. Does `login` work against Garmin SSO today with a dedicated account, and is it needed for `device download`? Not tested: it needs the account. The first run of `build.yml` after the secrets are added answers it.
2. Where does the CLI's `device download` put the files when `HOME` is `/github/home` (a container job), and does `monkeyc` find them there? The paths above come from the CLI's source; the compile in the container has not been run yet. The workflow links `$HOME/.Garmin` to `/root/.Garmin` so `monkeyc` finds the files; still untested until the secrets exist.
3. Does `monkeyc` from the Linux SDK 9.3.0 run on plain `openjdk-17-jre-headless` in `ubuntu:22.04` with no other libraries? Expected (compile needs only Java), not run.
4. Does `fr265` (416x416 AMOLED) run the simulator under Xvfb on Linux with SDK 9.3.0? Needed before simulator tests move into CI.
5. Is `actions/cache` of device files acceptable under clause I.b? The agreement does not say. Avoid it, or ask Garmin developer support.
6. If a face signed with a different key replaces one signed with the real key on a watch, are its settings and Storage kept? Not researched. It decides whether releases must always be signed with the same key.
7. The exact pass/fail output of `monkeydo -t` on Linux with SDK 9.3.0. `scripts/run-tests.sh` parses the macOS output (`RESULTS`, `PASSED`, `FAILED`); capture a Linux sample before reusing it in CI.
8. When does the `ubuntu:22.04` container stop being practical? Standard support for Ubuntu 22.04 is reported to end in 2027-05 (secondary source), and Garmin's webkit 4.1 bug is still open (https://forums.garmin.com/developer/connect-iq/i/bug-reports/upgrade-sdk-deps-so-modern-linux-distros-work).
9. Does `agreement accept` with an old hash fail when Garmin changes the agreement? The job would then stop until the maintainer reads the new agreement and updates `AGREEMENT_HASH`.
