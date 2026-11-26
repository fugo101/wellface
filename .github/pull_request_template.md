<!--
Title: Conventional Commits, for example "fix(fields): ..." or "docs: ...".
It becomes the commit subject on main (squash merge). See CONTRIBUTING.md.
Never paste personal data here (names, emails, machine paths, your own watch's
numbers, your developer key); this repository is public.
-->

Closes #

## Summary

<!-- What changes and why, in a few lines. Device ports, new metrics and render-path changes need an issue first. -->

## Evidence

<!-- How you tested it. Paste the result of the checks, or say why one does not apply. -->

- [ ] `scripts/build-release.sh` builds with zero warnings
- [ ] `scripts/run-tests.sh` passes
- [ ] Visual change: before and after screenshots attached (`scripts/capture.sh`), Always On checked with the heat map if touched
- [ ] Scripts, tools or workflows changed: `shellcheck scripts/*.sh`, `ruff check tools` and `actionlint` pass
- [ ] Docs-only change: none of the above needed; links checked

## Checklist

<!-- Tick what applies; delete lines that do not. -->

- [ ] New logic is in `FaceModel` with a test; drawing and sensor code stay thin (`CODING_STANDARDS.md`)
- [ ] Colors come from the theme, no literal colors
- [ ] Render-path change: timings measured before and after, none worse (`docs/build.md`, "Timing build")
- [ ] Generated files (fonts, font catalog, contours) regenerated with the scripts, not edited by hand
- [ ] Golden values re-recorded only for an intended change, and checked against an independent computation
- [ ] Forerunner 265 pixels are unchanged (golden tests and `scripts/capture.sh --compare`), or the change is meant to alter them and says so
- [ ] Device port: simulator screenshots, Always On heat map, on-watch confirmation, and I am listed in `CODEOWNERS` for the device
- [ ] `docs/spec.md`, `docs/design-sync.md`, `docs/build.md` or `GLOSSARY.md` updated where this change alters them
- [ ] No personal data, no developer key, nothing from the Garmin SDK or device files
