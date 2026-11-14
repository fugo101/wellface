#!/usr/bin/env bash
# The watch's GARMIN/Apps/LOGS folder over USB: list it, create an empty log
# file there (a log is written only if its file exists), copy a log back, or
# delete one.
# Compiles the MTP helper (tools/sideload/mtp_logs.c) the first time, like
# scripts/sideload.sh, and needs the same setup (libmtp, a C compiler, no
# MTP app holding the watch).
#
# Usage: scripts/watch-logs.sh list
#        scripts/watch-logs.sh create <NAME>          e.g. WELLFACE.PRF
#        scripts/watch-logs.sh get <NAME> <local file>
#        scripts/watch-logs.sh delete <NAME>
# Exit codes: 0 done, 1 not found or not copied, 2 could not run.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN="$ROOT/bin"
HELPER="$BIN/mtp-logs"
SOURCE="$ROOT/tools/sideload/mtp_logs.c"

die() { echo "error: $*" >&2; exit 2; }

for app in OpenMTP "Garmin Express"; do
    if pgrep -xiq "$app"; then
        die "$app is running and holds the watch; quit it fully, then try again"
    fi
done

if [[ ! -x "$HELPER" || "$SOURCE" -nt "$HELPER" ]]; then
    if command -v pkg-config >/dev/null && pkg-config --exists libmtp; then
        flags="$(pkg-config --cflags --libs libmtp)"
    elif command -v brew >/dev/null && prefix="$(brew --prefix libmtp 2>/dev/null)" \
            && [[ -f "$prefix/include/libmtp.h" ]]; then
        flags="-I$prefix/include -L$prefix/lib -lmtp"
    else
        die "libmtp not found; install it (macOS: brew install libmtp)"
    fi
    command -v cc >/dev/null || die "no C compiler (cc) on PATH"
    mkdir -p "$BIN"
    # shellcheck disable=SC2086  # the flags are meant to split into words
    cc -Wall -Wextra -O2 "$SOURCE" -o "$HELPER" $flags || die "could not compile the MTP helper"
fi

empty="$(mktemp)"
trap 'rm -f "$empty"' EXIT
case "${1:-}" in
    list) [[ $# -eq 1 ]] || die "usage: scripts/watch-logs.sh list"; args=(list) ;;
    create) [[ $# -eq 2 ]] || die "usage: scripts/watch-logs.sh create <NAME>"; args=(put "$empty" "$2") ;;
    get) [[ $# -eq 3 ]] || die "usage: scripts/watch-logs.sh get <NAME> <local file>"; args=(get "$2" "$3") ;;
    delete) [[ $# -eq 2 ]] || die "usage: scripts/watch-logs.sh delete <NAME>"; args=(del "$2") ;;
    *) die "usage: scripts/watch-logs.sh list | create <NAME> | get <NAME> <local file> | delete <NAME>" ;;
esac

# libusb and libmtp print harmless notes for every session (see sideload.sh).
NOISE='^Device [0-9]+ \(VID=|libusb_detach_kernel_driver|extended association type'
set +e
"$HELPER" "${args[@]}" 2> >(grep -v -E "$NOISE" >&2) | grep -v -E "$NOISE"
status=${PIPESTATUS[0]}
set -e
exit "$status"
