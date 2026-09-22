#!/usr/bin/env bash
# ported-scripts.sh — regression tests for ref-ported behavior.
set -uo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
FAIL=0

pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s\n' "$1"; FAIL=1; }

# cache.sh throttle loop must parse (regression: fi-for-done typo).
if bash -n "$ROOT/config/quickshell/hyprquickpaper/cache.sh"; then
    pass "hyprquickpaper cache.sh parses"
else
    fail "hyprquickpaper cache.sh parses"
fi

# No players here: active-player exits 1, marquee emits empty JSON.
if "$ROOT/scripts/kome-active-player" >/dev/null 2>&1; then
    fail "kome-active-player exits 1 with no players"
else
    pass "kome-active-player exits 1 with no players"
fi

out="$(timeout 3 bash "$ROOT/scripts/kome-mpris-marquee" 2>/dev/null | head -n 1)"
if printf '%s' "$out" | jq -e '.class == "empty"' >/dev/null 2>&1; then
    pass "kome-mpris-marquee emits empty JSON with no players"
else
    fail "kome-mpris-marquee emits empty JSON with no players (got: $out)"
fi

# Recorder without the binary fails clean, exit 1.
if command -v gpu-screen-recorder >/dev/null 2>&1; then
    pass "kome-record needs gsr (present, skipped)"
else
    if bash "$ROOT/scripts/kome-record" >/dev/null 2>&1; then
        fail "kome-record exits 1 without gsr"
    else
        pass "kome-record exits 1 without gsr"
    fi
fi

# Cursor outputs the dot or nothing (blink phases).
out="$(bash "$ROOT/scripts/kome-password-cursor")"
if [[ "$out" == "●" || -z "$out" ]]; then
    pass "kome-password-cursor outputs dot or blank"
else
    fail "kome-password-cursor outputs dot or blank (got: $out)"
fi

# Recorder bind present.
if grep -q 'kome-record' "$ROOT/config/hypr/modules/binds.lua"; then
    pass "binds.lua has recorder bind"
else
    fail "binds.lua has recorder bind"
fi

# Night light wired by default (script + bind, no provider flag).
if [[ -x "$ROOT/scripts/kome-gammastep" ]]; then
    pass "kome-gammastep installed executable"
else
    fail "kome-gammastep installed executable"
fi
if grep -q 'kome-gammastep' "$ROOT/config/hypr/modules/binds.lua"; then
    pass "binds.lua has night-light bind"
else
    fail "binds.lua has night-light bind"
fi

# Ported config dirs present.
for d in btop cava fastfetch shell starship; do
    if [[ -d "$ROOT/config/$d" ]]; then
        pass "config/$d exists"
    else
        fail "config/$d exists"
    fi
done

if [[ "$FAIL" -eq 0 ]]; then
    echo "=== ported-scripts: all pass ==="
else
    echo "=== ported-scripts: FAILURES ==="
fi
exit "$FAIL"
