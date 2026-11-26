#!/usr/bin/env bash
# Release builds for GitHub Releases: one PRG per device in manifest.xml,
# signed with your developer key (CIQ_DEV_KEY), into
# bin/release/v<version>/wellface-<device>.prg, plus SHA256SUMS, LICENSE, NOTICE
# and the font licenses (OFL).
# The build flags are the ones of scripts/build-release.sh. It does not
# publish anything. To publish, after tagging:
#   gh release create v0.1.0 bin/release/v0.1.0/* --title v0.1.0 --notes-file <notes>
#
# Usage: scripts/release.sh <semver>     e.g. scripts/release.sh 0.1.0
# The arguments are checked before common.sh, so a wrong call gets the usage
# message even without the SDK or a key.
if [[ $# -ne 1 ]]; then
    echo "usage: scripts/release.sh <semver>  (for example 0.1.0)" >&2
    exit 2
fi
VERSION="$1"
semver='^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-[0-9A-Za-z.-]+)?$'
if [[ ! "$VERSION" =~ $semver ]]; then
    echo "error: '$VERSION' is not a semantic version (MAJOR.MINOR.PATCH, for example 0.1.0)" >&2
    exit 2
fi
source "$(dirname "$0")/common.sh"

OUT="$BIN/release/v$VERSION"
[[ ! -e "$OUT" ]] || die "bin/release/v$VERSION already exists; remove it or pick a new version"

devices="$(manifest_products)"
[[ -n "$devices" ]] || die "no <iq:product> found in manifest.xml"

sha256() {
    if command -v sha256sum >/dev/null; then sha256sum "$@"; else shasum -a 256 "$@"; fi
}

# The compiler writes its intermediate files (gen/, mir/, *.debug.xml) next to
# the PRG, so each build runs in a work folder and only the PRG is kept.
mkdir -p "$OUT"
for DEVICE in $devices; do
    echo "== $DEVICE"
    work="$OUT/.work-$DEVICE"
    mkdir -p "$work"
    compile "$work/wellface-$DEVICE.prg" -r --build-stats 0
    mv "$work/wellface-$DEVICE.prg" "$OUT/"
    rm -rf "$work"
done

# The licenses travel with the binaries (Apache-2.0 for the code, OFL 1.1 for
# the fonts compiled into the PRG).
cp "$ROOT/LICENSE" "$ROOT/NOTICE" "$ROOT"/resources/fonts/OFL-*.txt "$OUT/"

(cd "$OUT" && sha256 wellface-*.prg | tee SHA256SUMS)
echo "built v$VERSION for: $(echo "$devices" | tr '\n' ' ')"
echo "files are in bin/release/v$VERSION (not published)"
