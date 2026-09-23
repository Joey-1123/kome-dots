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

# No absolute checkout paths in shipped scripts (regression: kome-theme
# fell back to /home/joey/projects/rice when KOME_ROOT was unset).
if [[ -n "$(grep -rn "/home/joey" "$ROOT/scripts/" "$ROOT/install/" 2>/dev/null | grep -v tests | head -n 3)" ]]; then
    fail "no absolute checkout paths in scripts/+install/"
else
    pass "no absolute checkout paths in scripts/+install/"
fi

# Recorder must not guess a monitor name (regression: eDP-1 fallback
# recorded the wrong screen when detection failed).
if grep -qE "eDP-1|HDMI-A-1|DP-1" "$ROOT/scripts/kome-record"; then
    fail "kome-record has no monitor-name literals"
else
    pass "kome-record has no monitor-name literals"
fi
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

# Preset command exists in help and lists known presets.
theme_usage="$(bash "$ROOT/scripts/kome-theme" 2>&1 || true)"
if [[ "$theme_usage" == *'preset'* ]]; then
    pass "kome-theme usage mentions preset"
else
    fail "kome-theme usage mentions preset"
fi

# Unknown preset rejected without touching state.
preset_err="$(bash "$ROOT/scripts/kome-theme" preset nosuchtheme 2>&1 || true)"
if [[ "$preset_err" == *'unknown'* ]]; then
    pass "kome-theme preset rejects unknown names"
else
    fail "kome-theme preset rejects unknown names"
fi

# Presets list command names the shipped presets.
preset_out="$(bash "$ROOT/scripts/kome-theme" presets 2>&1 || true)"
if [[ "$preset_out" == *'gruvbox'* && "$preset_out" == *'catppuccin-mocha'* && "$preset_out" == *'tokyo-night'* ]]; then
    pass "kome-theme presets lists shipped presets"
else
    fail "kome-theme presets lists shipped presets (got: $preset_out)"
fi

# Cava colors come from matugen (no static gradient hexes in repo).
if grep -q "templates.cava" "$ROOT/config/matugen/config.toml" && [[ -f "$ROOT/config/matugen/templates/cava-config" ]]; then
    pass "cava template registered in matugen config"
else
    fail "cava template registered in matugen config"
fi
if grep -vE "^[[:space:]]*[;#]" "$ROOT/config/matugen/templates/cava-config" | grep -qE "gradient_color_[0-9] = '#[0-9a-fA-F]{6}'"; then
    fail "cava template has no hardcoded gradient hexes"
else
    pass "cava template has no hardcoded gradient hexes"
fi
if [[ -f "$ROOT/config/cava/config" ]]; then
    fail "no static cava config shadows generated output"
else
    pass "no static cava config shadows generated output"
fi

if [[ "$FAIL" -eq 0 ]]; then
    echo "=== ported-scripts: all pass ==="
else
    echo "=== ported-scripts: FAILURES ==="
fi
exit "$FAIL"
