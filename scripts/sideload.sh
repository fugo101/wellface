#!/usr/bin/env bash
# Installs the face on the watch over the USB cable, in one command:
# builds the release PRG (unless a PRG is given), compiles the MTP helper
# (tools/sideload/mtp_push.c) if needed, and copies the PRG to
# GARMIN/Apps/WELLFACE.PRG, replacing any copy still waiting there. The
# helper confirms exactly one full-size copy on the watch afterwards.
#
# Usage: scripts/sideload.sh [file.prg]
# Needs: libmtp (macOS: brew install libmtp) and a C compiler. Building also
# needs CIQ_DEV_KEY, like the other build scripts.
#
# Exit codes: 0 copied and confirmed, 1 copy not confirmed, 2 could not run
# (no watch, an MTP app holding it, missing tools, build failed).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN="$ROOT/bin"
HELPER="$BIN/mtp-push"
SOURCE="$ROOT/tools/sideload/mtp_push.c"
REMOTE="WELLFACE.PRG"

die() { echo "error: $*" >&2; exit 2; }

# The PRG to send: the argument, or a fresh release build.
if [[ $# -gt 1 ]]; then
    die "usage: scripts/sideload.sh [file.prg]"
elif [[ $# -eq 1 ]]; then
    PRG="$1"
    [[ -f "$PRG" ]] || die "$PRG not found"
else
    "$ROOT/scripts/build-release.sh" || die "release build failed"
    PRG="$BIN/wellface-release.prg"
fi

# Only one program can hold the watch's USB connection at a time.
for app in OpenMTP "Garmin Express"; do
    if pgrep -xiq "$app"; then
        die "$app is running and holds the watch; quit it fully, then try again"
    fi
done

# libmtp's compiler and linker flags, from pkg-config or Homebrew.
mtp_flags() {
    if command -v pkg-config >/dev/null && pkg-config --exists libmtp; then
        pkg-config --cflags --libs libmtp
    elif command -v brew >/dev/null && prefix="$(brew --prefix libmtp 2>/dev/null)" \
            && [[ -f "$prefix/include/libmtp.h" ]]; then
        echo "-I$prefix/include -L$prefix/lib -lmtp"
    else
        return 1
    fi
}

# (Re)compile the helper when it is missing or older than its source.
if [[ ! -x "$HELPER" || "$SOURCE" -nt "$HELPER" ]]; then
    flags="$(mtp_flags)" || die "libmtp not found; install it (macOS: brew install libmtp)"
    command -v cc >/dev/null || die "no C compiler (cc) on PATH"
    mkdir -p "$BIN"
    # shellcheck disable=SC2086  # the flags are meant to split into words
    cc -Wall -Wextra -O2 "$SOURCE" -o "$HELPER" $flags || die "could not compile the MTP helper"
fi

# libusb and libmtp print harmless notes for every session on the FR265
# (device found, kernel driver detach, extended association type), libmtp's
# on stdout and libusb's on stderr; hide them on both.
NOISE='^Device [0-9]+ \(VID=|libusb_detach_kernel_driver|extended association type'
set +e
"$HELPER" "$PRG" "$REMOTE" 2> >(grep -v -E "$NOISE" >&2) | grep -v -E "$NOISE"
status=${PIPESTATUS[0]}
set -e
if [[ $status -eq 0 ]]; then
    echo "unplug the watch: it installs the face and then removes the PRG from GARMIN/Apps"
fi
exit $status
