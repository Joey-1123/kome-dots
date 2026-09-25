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

# Waybar follows the compact three-group desktop layout.
waybar_config="$ROOT/config/waybar/config.jsonc"
waybar_style="$ROOT/config/waybar/style.css"
if grep -Fq '"modules-left": ["cpu", "custom/gpu", "memory", "temperature"]' "$waybar_config" \
    && grep -Fq '"modules-center": ["clock"]' "$waybar_config" \
    && grep -Fq '"modules-right": ["custom/mpris-marquee", "pulseaudio", "custom/power"]' "$waybar_config"; then
    pass "Waybar uses the compact reference module groups"
else
    fail "Waybar uses the compact reference module groups"
fi
if grep -Fq 'background-color: rgba(20, 20, 20, 0.5)' "$waybar_style" \
    && grep -Fq 'border-radius: 10px' "$waybar_style" \
    && grep -Fq 'font-size: 11px' "$waybar_style"; then
    pass "Waybar uses the compact reference surface treatment"
else
    fail "Waybar uses the compact reference surface treatment"
fi
if grep -Fq '"on-click": "pavucontrol"' "$waybar_config" \
    && ! grep -Fq 'toggle-gammastep' "$waybar_config"; then
    pass "Waybar click actions do not repurpose temperature clicks"
else
    fail "Waybar click actions do not repurpose temperature clicks"
fi

# Application shells share a transparent, minimal surface treatment.
if grep -Eq 'bg:[[:space:]]+\{\{colors\.background\.default\.hex\}\}e6;' \
    "$ROOT/config/matugen/templates/rofi-colors.rasi" \
    && grep -Fq 'bg-selected: @primary-container;' "$ROOT/config/rofi/config.rasi"; then
    pass "Rofi uses a translucent generated surface and selection"
else
    fail "Rofi uses a translucent generated surface and selection"
fi
if grep -Fq 'background_opacity 0.90' "$ROOT/config/kitty/kitty.conf" \
    && grep -Fq 'dynamic_background_opacity yes' "$ROOT/config/kitty/kitty.conf"; then
    pass "Kitty uses a translucent minimal terminal surface"
else
    fail "Kitty uses a translucent minimal terminal surface"
fi
if [[ -x "$ROOT/scripts/kome-kitty-theme" ]] \
    && [[ -f "$ROOT/config/kitty/theme.conf" ]] \
    && grep -Fq 'include theme.conf' "$ROOT/config/kitty/kitty.conf" \
    && find "$ROOT/config/kitty/themes" -maxdepth 1 -type f -name '*.conf' | grep -q .; then
    pass "Kitty has a local theme library and selector"
else
    fail "Kitty has a local theme library and selector"
fi
kitty_iso="$(mktemp -d)"
mkdir -p "$kitty_iso/kitty/themes"
cp "$ROOT/config/kitty/themes/JetBrains_Darcula.conf" "$kitty_iso/kitty/themes/"
if XDG_CONFIG_HOME="$kitty_iso" "$ROOT/scripts/kome-kitty-theme" list 2>/dev/null | grep -Fxq 'JetBrains_Darcula' \
    && XDG_CONFIG_HOME="$kitty_iso" "$ROOT/scripts/kome-kitty-theme" apply JetBrains_Darcula >/dev/null 2>&1 \
    && [[ "$(XDG_CONFIG_HOME="$kitty_iso" "$ROOT/scripts/kome-kitty-theme" current)" == 'JetBrains_Darcula' ]] \
    && XDG_CONFIG_HOME="$kitty_iso" "$ROOT/scripts/kome-kitty-theme" reset >/dev/null 2>&1 \
    && [[ "$(XDG_CONFIG_HOME="$kitty_iso" "$ROOT/scripts/kome-kitty-theme" current)" == 'generated' ]]; then
    pass "kome-kitty-theme applies and resets a theme"
else
    fail "kome-kitty-theme applies and resets a theme"
fi
rm -rf "$kitty_iso"
if grep -Fq 'include themes/Bright_Lights.conf' "$ROOT/config/kitty/theme.conf" \
    && [[ -f "$ROOT/config/kitty/themes/Bright_Lights.conf" ]]; then
    pass "Kitty defaults to the Bright Lights theme"
else
    fail "Kitty defaults to the Bright Lights theme"
fi
kitty_iso="$(mktemp -d)"
mkdir -p "$kitty_iso/kitty/themes"
cp "$ROOT/config/kitty/themes/Bright_Lights.conf" "$kitty_iso/kitty/themes/"
cp "$ROOT/config/kitty/theme.conf" "$kitty_iso/kitty/theme.conf"
if [[ "$(XDG_CONFIG_HOME="$kitty_iso" "$ROOT/scripts/kome-kitty-theme" current)" == 'Bright_Lights' ]] \
    && XDG_CONFIG_HOME="$kitty_iso" "$ROOT/scripts/kome-kitty-theme" list --json 2>/dev/null \
        | grep -Fq '"name":"Bright_Lights"' \
    && XDG_CONFIG_HOME="$kitty_iso" "$ROOT/scripts/kome-kitty-theme" list --json 2>/dev/null \
        | grep -Fq '"background":"#191919"'; then
    pass "kome-kitty-theme resolves the included default and lists themes as json"
else
    fail "kome-kitty-theme resolves the included default and lists themes as json"
fi
rm -rf "$kitty_iso"
if grep -Fq 'inner_color = rgba({{colors.surface.default.hex_stripped}}00)' \
    "$ROOT/config/matugen/templates/hyprlock-colors.conf" \
    && grep -Fq 'outer_color = rgba({{colors.on_surface.default.hex_stripped}}aa)' \
    "$ROOT/config/matugen/templates/hyprlock-colors.conf"; then
    pass "Hyprlock keeps its input surface transparent"
else
    fail "Hyprlock keeps its input surface transparent"
fi
if grep -Fq 'background-color: rgba(12, 12, 12, 0.2)' "$ROOT/config/wlogout/style.css" \
    && grep -Fq 'border-radius: 50%' "$ROOT/config/wlogout/style.css" \
    && [[ -f "$ROOT/config/wlogout/layout" ]]; then
    pass "Wlogout uses a minimal translucent circular layout"
else
    fail "Wlogout uses a minimal translucent circular layout"
fi
if grep -Fq 'orientation: ListView.Horizontal' \
    "$ROOT/config/quickshell/hyprquickpaper/shell.qml" \
    && ! grep -Fq 'color: "#C4000000"' \
    "$ROOT/config/quickshell/hyprquickpaper/shell.qml"; then
    pass "Wallpaper picker uses a transparent horizontal filmstrip"
else
    fail "Wallpaper picker uses a transparent horizontal filmstrip"
fi
if grep -Fq 'Theme.alpha(Theme.bg,' "$ROOT/config/quickshell/SettingsWindow.qml" \
    && grep -Fq 'Theme.alpha(Theme.bgCard' "$ROOT/config/quickshell/SettingsSection.qml"; then
    pass "Kome system panel uses a translucent application surface"
else
    fail "Kome system panel uses a translucent application surface"
fi
for helper in gpu_usage.sh mpris-marquee.sh playerctl-active.sh toggle-gammastep; do
    if [[ -x "$ROOT/config/waybar/scripts/$helper" ]]; then
        pass "Waybar helper $helper is executable"
    else
        fail "Waybar helper $helper is executable"
    fi
done
if [[ -f "$ROOT/config/waybar/LICENSE" ]]; then
    pass "Waybar reference license notice is present"
else
    fail "Waybar reference license notice is present"
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

# Cheat-sheet covers every bind in binds.lua. Grouped H/J/K/L rows are
# expanded before matching; everything else must appear literally.
cheat_missing=0
cheat_list="$(bash "$ROOT/scripts/kome-keybinds" --list)"
cheat_expanded="$(printf '%s' "$cheat_list" | while IFS= read -r line; do
    if [[ "$line" == *'H/J/K/L'* ]]; then
        for letter in H J K L; do
            printf '%s\n' "${line//H\/J\/K\/L/$letter}"
        done
    else
        printf '%s\n' "$line"
    fi
done)"
while IFS= read -r key; do
    [[ -z "$key" ]] && continue
    if [[ "$key" =~ ^SUPER\ \+\ [0-9]$ ]] || [[ "$key" =~ ^SUPER\ \+\ SHIFT\ \+\ [0-9]$ ]]; then
        pattern="1-0"
    elif [[ "$key" == XF86* ]]; then
        pattern="XF86"
    elif [[ "$key" == *"mouse"* || "$key" == *"code:"* ]]; then
        pattern="mouse"
    else
        pattern="$key"
    fi
    if [[ "$cheat_expanded" != *"$pattern"* ]]; then
        printf 'missing from cheat-sheet: %s\n' "$key"
        cheat_missing=1
    fi
done < <(lua "$ROOT/tests/extract-binds.lua" "$ROOT/config/hypr/modules/binds.lua")
if [[ "$cheat_missing" -eq 0 ]]; then
    pass "cheat-sheet covers every bind"
else
    fail "cheat-sheet covers every bind"
fi

# Update notifier round-trips timer units in an isolated HOME.
iso_home="$(mktemp -d)"
if HOME="$iso_home" bash "$ROOT/scripts/kome-updates" enable >/dev/null 2>&1 \
    && [[ -f "$iso_home/.config/systemd/user/kome-updates.timer" ]] \
    && HOME="$iso_home" bash "$ROOT/scripts/kome-updates" disable >/dev/null 2>&1 \
    && [[ ! -f "$iso_home/.config/systemd/user/kome-updates.timer" ]]; then
    pass "kome-updates enable/disable round-trips units"
else
    fail "kome-updates enable/disable round-trips units"
fi
rm -rf "$iso_home"
if bash "$ROOT/scripts/kome-updates" check >/dev/null 2>&1; then
    pass "kome-updates check exits 0"
else
    fail "kome-updates check exits 0"
fi

# Game mode round-trips live state when a compositor answers.
if hyprctl version >/dev/null 2>&1; then
    if bash "$ROOT/scripts/kome-gamemode" on >/dev/null 2>&1 \
        && bash "$ROOT/scripts/kome-gamemode" off >/dev/null 2>&1 \
        && hyprctl getoption animations:enabled -j | grep -q '"bool": true'; then
        pass "kome-gamemode on/off round-trips live state"
    else
        fail "kome-gamemode on/off round-trips live state"
    fi
else
    pass "kome-gamemode live round-trip (skipped, no compositor)"
fi
if grep -q 'kome-gamemode' "$ROOT/config/hypr/modules/binds.lua"; then
    pass "binds.lua has game-mode bind"
else
    fail "binds.lua has game-mode bind"
fi

# Uninstaller restores a fabricated backup in an isolated HOME.
iso_home2="$(mktemp -d)"
mkdir -p "$iso_home2/.config/kitty" "$iso_home2/.config/kome/backups/b1/.config/kitty"
echo "ORIGINAL" > "$iso_home2/.config/kitty/kitty.conf"
ln -s "$ROOT/config/kitty/kitty.conf" "$iso_home2/.config/kitty/from-repo.conf"
printf 'L %s/.config/kitty/from-repo.conf\nM .config/kitty/kitty.conf\n' "$iso_home2" > "$iso_home2/.config/kome/backups/b1/manifest"
mv "$iso_home2/.config/kitty/kitty.conf" "$iso_home2/.config/kome/backups/b1/.config/kitty/kitty.conf"
if HOME="$iso_home2" bash "$ROOT/scripts/kome-uninstall" --backup "$iso_home2/.config/kome/backups/b1" >/dev/null 2>&1 \
    && [[ ! -e "$iso_home2/.config/kitty/from-repo.conf" ]] \
    && [[ "$(cat "$iso_home2/.config/kitty/kitty.conf")" == "ORIGINAL" ]]; then
    pass "kome-uninstall restores backup in isolated HOME"
else
    fail "kome-uninstall restores backup in isolated HOME"
fi
if HOME="$iso_home2" bash "$ROOT/scripts/kome-uninstall" --backup >/dev/null 2>&1; then
    fail "kome-uninstall rejects --backup without a value"
else
    pass "kome-uninstall rejects --backup without a value"
fi
mkdir -p "$iso_home2/.config/kome/backups/empty"
if HOME="$iso_home2" bash "$ROOT/scripts/kome-uninstall" --backup "$iso_home2/.config/kome/backups/empty" >/dev/null 2>&1; then
    fail "kome-uninstall refuses without a manifest"
else
    pass "kome-uninstall refuses without a manifest"
fi
# User-replaced symlink is left alone; traversal entries refused.
mkdir -p "$iso_home2/.config/kome/backups/b2"
ln -s /etc/hostname "$iso_home2/.config/kitty/foreign.conf"
printf 'L %s/.config/kitty/foreign.conf\nM ../escape\n' "$iso_home2" > "$iso_home2/.config/kome/backups/b2/manifest"
out_u="$(HOME="$iso_home2" bash "$ROOT/scripts/kome-uninstall" --backup "$iso_home2/.config/kome/backups/b2" 2>&1)"
if [[ -L "$iso_home2/.config/kitty/foreign.conf" ]] && [[ "$out_u" == *'no longer kome-managed'* && "$out_u" == *'refusing unsafe entry'* ]]; then
    pass "kome-uninstall skips foreign symlinks and unsafe entries"
else
    fail "kome-uninstall skips foreign symlinks and unsafe entries"
fi
rm -rf "$iso_home2"

# Presets ship real palettes covering every template token.
preset_bad=0
for pj in "$ROOT"/config/matugen/presets/*.json; do
    [[ -f "$pj" ]] || continue
    # collect every role any template references
    for tok in $(grep -rhoE '\{\{colors\.[a-z_0-9]+\.default\.' "$ROOT"/config/matugen/templates/ | sed 's/{{colors\.//; s/\.default\.//' | sort -u); do
        if ! jq -e --arg k "$tok" 'has($k)' "$pj" >/dev/null 2>&1; then
            printf 'palette %s missing role: %s\n' "$(basename "$pj")" "$tok"
            preset_bad=1
        fi
    done
done
if [[ "$preset_bad" -eq 0 ]]; then
    pass "presets cover every template colour role"
else
    fail "presets cover every template colour role"
fi

if ! bash "$ROOT/tests/settings-pages.sh"; then
    FAIL=1
fi

if [[ "$FAIL" -eq 0 ]]; then
    echo "=== ported-scripts: all pass ==="
else
    echo "=== ported-scripts: FAILURES ==="
fi
exit "$FAIL"
