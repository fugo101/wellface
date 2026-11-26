# Contributing to Wellface

Wellface is a custom Connect IQ watch face for round AMOLED Garmin watches, written in Monkey C. The maintainer guarantees only the Garmin Forerunner 265. Issues and pull requests from outside are welcome. Everyone taking part follows the [Code of Conduct](CODE_OF_CONDUCT.md).

## Ways to contribute

- **Bug reports.** The face draws or behaves differently from the design ([`design/claude-design/`](design/claude-design/)), [`docs/spec.md`](docs/spec.md) or [`docs/decisions.md`](docs/decisions.md). A simulator screenshot helps; say which device and firmware you saw it on.
- **Ideas.** A new metric, theme or field kind. Check [`docs/decisions.md`](docs/decisions.md) first: many choices are already agreed, and a few are deliberately out of scope.
- **Device ports.** See [Device support](#device-support) below. Always an issue first.
- **Documentation.** Fixes and clarifications to the README, docs, glossary or research notes.
- **Code.** Fixes and features, after the issue-first step below where it applies.

Open an issue with one of the issue forms. For a security vulnerability, do not open an issue: follow [`SECURITY.md`](SECURITY.md). For questions, see [`SUPPORT.md`](SUPPORT.md).

The repository is public. Do not paste personal data into an issue, PR or comment: no real names or emails, no machine paths such as `/Users/<name>/...`, no developer key, and no health data from your own watch (step counts, heart rate and the like). Use made-up values.

## Open an issue first

Open an issue before you start on:

- a port to another device;
- a new metric, field kind or theme, or a change to the layout, the colors or what a field shows;
- a change to `source/FaceModel.mc` or the render path, to the refresh plan, or to how often data is read;
- anything that touches `docs/decisions.md`. A decision there is changed only by the maintainer, in the same PR as the change that needs it.

Small fixes elsewhere (a typo, a broken link, an obvious bug with a test) can go straight to a PR.

New issues get the `needs-triage` label. The maintainer then moves them to one of these ([`docs/agents/triage-labels.md`](docs/agents/triage-labels.md)):

| Label | Meaning |
| --- | --- |
| `needs-info` | Waiting on the reporter for more information |
| `ready-for-agent` | Fully specified; an automated agent can implement it |
| `ready-for-human` | Fully specified; needs a human implementer |
| `wontfix` | Will not be actioned |

Device labels such as `device: fr265` say which device an issue is about. An issue labeled `ready-for-human`, `good first issue` or `help wanted` is open to outside contributors. Say in the issue that you are taking it, to avoid duplicate work.

## Device support

Wellface is a community project. Devices come in two kinds:

| Kind | Meaning |
| --- | --- |
| Maintained | The maintainer owns the watch, tests every release on it and guarantees it works. Today: the Forerunner 265 only. |
| Community | Someone else owns the watch, ported the face to it and looks after it. No guarantee from the maintainer. |

To add a community device:

1. **Open an issue first** with the "Device port" form. Say which device, its screen and API level, and that you own one. Until the multi-device refactor lands (the first planned issue, "make adding a device purely additive", which ends with an experimental 360×360 Forerunner 265S sample port that runs in the simulator only), a port needs more changes than it should, so agree the approach before you write code.
2. **The porter owns the device.** A port that cannot be confirmed on a real watch is not accepted. The only exception is a sample port the maintainer marks "experimental / simulator-only" on purpose.
3. **The PR shows evidence:** simulator screenshots of the main states and of Always On with the heat map (File → View Screen Heat Map; menu names may differ slightly), and your confirmation that you ran it on the watch. Run the build, test and capture scripts with `CIQ_DEVICE=<id>` for your device as well as with the default `fr265`.
4. **The porter becomes the device's maintainer** and is listed in [`.github/CODEOWNERS`](.github/CODEOWNERS) for that device's files. GitHub then asks you to review changes to those files.
5. **A port must not change a single Forerunner 265 pixel.** The Forerunner 265 golden tests (`tests/GoldenValues.mc`) stay unchanged, and `scripts/capture.sh <dir> --compare <baseline dir>` reports no difference for it.
6. **An unmaintained device is removed.** If a community device breaks across a release and nobody fixes it, the maintainer removes it from `manifest.xml`. It can be added again with a new port.

## Development setup

Follow [README › Build, test and sideload](README.md#build-test-and-sideload) for the tools, and [`docs/build.md`](docs/build.md) for every script. You generate your own developer key; never commit it, and never commit anything from the Garmin SDK or device files (the Connect IQ developer agreement does not allow redistributing them).

Before you open a PR, run what applies:

```sh
scripts/build-release.sh   # must build with zero warnings; type checking is strict
scripts/run-tests.sh       # unit tests in the simulator
```

- **A visual change:** capture before and after with `scripts/capture.sh <dir>` and `--compare`, and put the screenshots in the PR. Check Always On with the heat map when the change touches it.
- **A change to a generator** (`tools/fontgen/`, `tools/contourgen/`): run `scripts/gen-fonts.sh` or `scripts/gen-contours.sh` and commit the output. Never edit the generated files by hand.
- **A change to `scripts/` or `tools/`:** run `shellcheck` on shell scripts and `ruff check` on Python.
- **A change to a workflow:** run `actionlint`.
- **A docs-only change:** check that links resolve and that nothing personal slipped in.

CI runs the lint checks and a compile-only build for every device in `manifest.xml`. The compile-only build needs repository secrets, so it does not run on pull requests from forks, and it is not required; the maintainer builds and tests your change locally. The simulator tests do not run in CI. `scripts/run-tests.sh` on your machine is the authority.

## Branches, commits and PR titles

- Work on a branch, not on `main`. Open the PR against `main`.
- Write commit messages and the PR title in [Conventional Commits](https://www.conventionalcommits.org/) form: `type(scope): summary`, for example `fix(fields): ...` or `docs: ...`. Allowed types: `feat`, `fix`, `perf`, `deps`, `revert`, `docs`, `style`, `chore`, `refactor`, `test`, `build`, `ci`. The `Conventional PR title` check enforces the PR title.
- PRs are squash-merged and nothing else, so the PR title becomes the commit subject on `main`. Keep one topic per PR.
- Fill in the PR template. Link the issue with `Closes #<number>`.

## Code and documentation rules

The reasons are in [`CODING_STANDARDS.md`](CODING_STANDARDS.md); in short:

- `FaceModel` is the only test seam. New logic goes there, with a test; drawing and sensor code stay thin.
- Colors come from the theme, never as a literal in layout or logic.
- Performance rules (static buffer, minute layer, what may be drawn each second) hold for every change to the render path.
- Fonts come from the generator only.
- Everything in the repo is in English: code, comments, docs, issues and PRs. The Claude Design export in `design/claude-design/` stays as exported ([Q51](docs/decisions.md)).
- Use the terms in [`GLOSSARY.md`](GLOSSARY.md) and avoid the synonyms it lists. A new domain term goes into the glossary in the same PR.
- Update [`docs/spec.md`](docs/spec.md), [`docs/design-sync.md`](docs/design-sync.md) or [`docs/build.md`](docs/build.md) in the same PR when a change alters what they describe.

## No personal identifiers

Do not commit or post usernames other than GitHub handles, email addresses, host paths, serial numbers or the personal numbers of your own watch (steps, goals, heart rate). Use placeholders such as `<path to your developer key>`.

## Review

The maintainer reviews every PR, on a best-effort basis. A PR is merged only when the required checks are green (`Conventional PR title` and the lint job) and review comments are resolved. Review follows [`CODING_STANDARDS.md`](CODING_STANDARDS.md).

## Releases

Releases follow [Semantic Versioning](https://semver.org/) and are published as GitHub Releases, with one `wellface-<device>.prg` per device in `manifest.xml`. The maintainer builds them locally with `scripts/release.sh <semver>` and the real developer key; the key never goes to CI. Release notes carry the install and uninstall steps.

## License

Wellface is licensed under Apache-2.0 ([`LICENSE`](LICENSE), [`NOTICE`](NOTICE)). By submitting a contribution, you agree that it is licensed under the same terms (Apache-2.0, section 5). There is no CLA and no DCO sign-off; a `Signed-off-by` line is optional. Do not add code, fonts or images under a license that is not compatible, and list third-party material in `NOTICE`.
