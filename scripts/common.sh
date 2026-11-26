#!/usr/bin/env bash
# Shared setup for the Wellface build scripts. Source it, do not run it.
#
# Needs:
#   CIQ_DEV_KEY  path to the developer key (RSA 4096, DER). Never printed.
#   CIQ_SDK      optional; defaults to the SDK the SDK Manager marked as current.
#   JUNGLE       optional; the jungle to build, set by the script (default: the face).
#   CIQ_DEVICE   optional; the device to build for (default: fr265, the maintained device).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEVICE="${CIQ_DEVICE:-fr265}"
BIN="$ROOT/bin"
JUNGLE="${JUNGLE:-$ROOT/monkey.jungle}"

die() { echo "error: $*" >&2; exit 2; }

# manifest_products: the device ids listed in manifest.xml, one per line.
manifest_products() {
    grep -o '<iq:product id="[^"]*"' "$ROOT/manifest.xml" | sed 's/^.*id="//; s/"$//'
}

if [[ -z "${CIQ_SDK:-}" ]]; then
    case "$(uname)" in
        Darwin) cfg="$HOME/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg" ;;
        *)      cfg="$HOME/.Garmin/ConnectIQ/current-sdk.cfg" ;;
    esac
    [[ -f "$cfg" ]] || die "no current SDK found; install one with the SDK Manager or set CIQ_SDK"
    CIQ_SDK="$(cat "$cfg")"
fi
CIQ_SDK="${CIQ_SDK%/}"
[[ -x "$CIQ_SDK/bin/monkeyc" ]] || die "CIQ_SDK does not point at a Connect IQ SDK"
command -v java >/dev/null || die "java is not on PATH; install a JDK"

# The key path itself is never echoed, so it cannot leak into logs.
[[ -n "${CIQ_DEV_KEY:-}" ]] || die "CIQ_DEV_KEY is not set (path to your developer key)"
[[ -r "$CIQ_DEV_KEY" ]] || die "CIQ_DEV_KEY does not point at a readable file"

mkdir -p "$BIN"

# Replaces the key path with a placeholder, in case a tool ever echoes it.
# Unbuffered, so a running app's log streams line by line.
mask_key() { KEY="$CIQ_DEV_KEY" perl -pe 'BEGIN { $| = 1; $k = $ENV{KEY} } s/\Q$k\E/<developer key>/g'; }

# compile <output.prg> [extra monkeyc flags...]
# Type checking comes from monkey.jungle (strict). Warnings are shown (-w) and
# any warning fails the build, so the project stays at zero warnings.
compile() {
    local out="$1"; shift
    local status=0
    COMPILE_LOG="$(mktemp)"
    trap 'rm -f "${COMPILE_LOG:-}"' EXIT
    "$CIQ_SDK/bin/monkeyc" -d "$DEVICE" -f "$JUNGLE" -o "$out" \
        -y "$CIQ_DEV_KEY" -w "$@" 2>&1 | mask_key | tee "$COMPILE_LOG" || status=$?
    if [[ $status -ne 0 ]] || ! grep -q "BUILD SUCCESSFUL" "$COMPILE_LOG"; then
        die "build failed"
    fi
    if grep -qi "^WARNING" "$COMPILE_LOG"; then
        die "build produced warnings (the project must build with zero warnings)"
    fi
    rm -f "$COMPILE_LOG"
}

# run_in_sim <app.prg>
# Starts the simulator (or focuses it) and loads the app. monkeydo stays
# attached and prints the app's log; press Ctrl+C to detach.
run_in_sim() {
    local prg="$1" out status
    "$CIQ_SDK/bin/connectiq"   # starts the simulator, or focuses it if running
    out="$(mktemp)"
    trap 'rm -f "${COMPILE_LOG:-}" "$out"' EXIT
    for _ in $(seq 1 30); do
        status=0
        "$CIQ_SDK/bin/monkeydo" "$prg" "$DEVICE" 2>&1 | mask_key | tee "$out" || status=$?
        grep -q "Unable to connect to simulator" "$out" || exit "$status"
        sleep 2   # the simulator is still starting
    done
    die "could not reach the simulator"
}
