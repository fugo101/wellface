#!/usr/bin/env bash
# Shared setup for the Wellface build scripts. Source it, do not run it.
#
# Needs:
#   CIQ_DEV_KEY  path to the developer key (RSA 4096, DER). Never printed.
#   CIQ_SDK      optional; defaults to the SDK the SDK Manager marked as current.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEVICE="fr265"
BIN="$ROOT/bin"

die() { echo "error: $*" >&2; exit 2; }

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
mask_key() { KEY="$CIQ_DEV_KEY" perl -pe 'BEGIN { $k = $ENV{KEY} } s/\Q$k\E/<developer key>/g'; }

# compile <output.prg> [extra monkeyc flags...]
# Type checking comes from monkey.jungle (strict). Warnings are shown (-w) and
# any warning fails the build, so the project stays at zero warnings.
compile() {
    local out="$1"; shift
    local status=0
    COMPILE_LOG="$(mktemp)"
    trap 'rm -f "${COMPILE_LOG:-}"' EXIT
    "$CIQ_SDK/bin/monkeyc" -d "$DEVICE" -f "$ROOT/monkey.jungle" -o "$out" \
        -y "$CIQ_DEV_KEY" -w "$@" 2>&1 | mask_key | tee "$COMPILE_LOG" || status=$?
    if [[ $status -ne 0 ]] || ! grep -q "BUILD SUCCESSFUL" "$COMPILE_LOG"; then
        die "build failed"
    fi
    if grep -qi "^WARNING" "$COMPILE_LOG"; then
        die "build produced warnings (the project must build with zero warnings)"
    fi
}
