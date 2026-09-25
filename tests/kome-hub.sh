#!/usr/bin/env bash
# kome-hub.sh — contract tests for the Quickshell control hub.
set -uo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
FAIL=0

pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s\n' "$1"; FAIL=1; }

contains() {
    local file="$1" text="$2" label="$3"
    if grep -Fq -- "$text" "$ROOT/$file"; then
        pass "$label"
    else
        fail "$label"
    fi
}

missing() {
    local file="$1" text="$2" label="$3"
    if grep -Fq -- "$text" "$ROOT/$file"; then
        fail "$label"
    else
        pass "$label"
    fi
}

contains config/quickshell/PerspectivePanel.qml "import Quickshell" \
    "panel motion imports Quickshell for reduced-motion detection"
contains config/quickshell/PerspectivePanel.qml 'KOME_REDUCED_MOTION' \
    "panel motion honors KOME_REDUCED_MOTION"
missing config/quickshell/PerspectivePanel.qml 'Easing.OutBack' \
    "panel motion has no entrance bounce"
contains config/quickshell/SettingsWindow.qml 'text: " KOME"' \
    "settings shell is branded as Kome"
contains config/quickshell/SettingsWindow.qml 'onClicked: root.selectedIndex = index' \
    "sidebar pages require an explicit click"
contains config/quickshell/SettingsWindow.qml 'activeFocusOnTab: true' \
    "sidebar pages are keyboard focusable"
contains config/quickshell/SettingsWindow.qml 'root.showing = true' \
    "settings show IPC sets panel state directly"
contains config/quickshell/SettingsWindow.qml 'root.showing = false' \
    "settings hide IPC sets panel state directly"
contains config/quickshell/SettingsWindow.qml 'property bool hovered: false' \
    "sidebar pages expose a hover state"
missing config/quickshell/SettingsWindow.qml 'onEntered: root.selectedIndex = index' \
    "sidebar hover does not change pages"
contains config/quickshell/SettingsWindow.qml 'leftMargin: 18' \
    "top-left corner accents do not overlap"
contains config/quickshell/SettingsWindow.qml 'rightMargin: 18' \
    "bottom-right corner accents do not overlap"
contains config/quickshell/SettingsWindow.qml 'width: parent.width - sidebar.width - parent.spacing * 2 - 1' \
    "page content reserves both sidebar row gaps"
missing config/quickshell/SettingsWindow.qml 'width: parent.width - sidebar.width - 29' \
    "page content does not use the overlapping legacy width"

iso_home="$(mktemp -d)"
trap 'rm -rf "$iso_home"' EXIT
mkdir -p "$iso_home/.config/kome" "$iso_home/.local/bin"
printf 'dark\n' >"$iso_home/.config/kome/mode"

if theme_state="$(HOME="$iso_home" XDG_CONFIG_HOME="$iso_home/.config" bash "$ROOT/scripts/kome-theme" state 2>/dev/null)" \
    && jq -e '.mode == "dark" and .preset == ""' <<<"$theme_state" >/dev/null; then
    pass "kome-theme state emits mode and preset"
else
    fail "kome-theme state emits mode and preset (got: ${theme_state:-no output})"
fi

cat >"$iso_home/.local/bin/checkupdates" <<'EOF'
#!/usr/bin/env sh
printf '%s\n' one two
EOF
for helper in yay paru; do
    cat >"$iso_home/.local/bin/$helper" <<'EOF'
#!/usr/bin/env sh
exit 0
EOF
done
chmod +x "$iso_home/.local/bin/checkupdates" "$iso_home/.local/bin/yay" "$iso_home/.local/bin/paru"
if update_count="$(HOME="$iso_home" PATH="$iso_home/.local/bin:/usr/bin:/bin" bash "$ROOT/scripts/kome-updates" count 2>/dev/null)" \
    && [[ "$update_count" == "2" ]]; then
    pass "kome-updates count emits a number"
else
    fail "kome-updates count emits a number (got: ${update_count:-no output})"
fi

if doctor_output="$(NO_COLOR=1 bash "$ROOT/scripts/kome-doctor" 2>&1)" \
    && [[ "$doctor_output" != *$'\033'* ]]; then
    pass "kome-doctor honors NO_COLOR"
else
    fail "kome-doctor honors NO_COLOR"
fi
if pgrep -x qs >/dev/null 2>&1 \
    && [[ "$doctor_output" == *"[WARN] osd (swayosd) not running"* ]]; then
    fail "kome-doctor recognizes quickshell as the OSD provider"
fi

contains config/quickshell/SettingsWindow.qml 'page: "KomePage"' \
    "Kome overview is the first hub page"
contains config/quickshell/SettingsWindow.qml 'page: "ShortcutsPage"' \
    "Shortcuts is available from the hub navigation"
contains config/quickshell/SettingsWindow.qml 'property alias showing: settingsState.showing' \
    "hub visibility survives Quickshell reloads"
contains config/quickshell/SettingsWindow.qml 'function showPage(name: string): void' \
    "hub exposes typed page navigation IPC"
contains config/quickshell/SettingsWindow.qml 'function runQuickAction(action: string): void' \
    "hub exposes typed quick-action IPC"
if [[ -f "$ROOT/config/quickshell/SettingsPages/KomePage.qml" ]]; then
    contains config/quickshell/KomeAppearance.qml 'height: 366' \
        "appearance card contains its wallpaper actions"
    contains config/quickshell/SettingsPages/KomePage.qml 'bottomPadding: 18' \
        "Kome page keeps bottom content clear of the panel edge"
    contains config/quickshell/SettingsPages/KomePage.qml '["qs", "ipc", "call", "settings", "hide"]' \
        "Kome actions close the hub through IPC"
    contains config/quickshell/SettingsPages/KomePage.qml '["kome-theme", "state"]' \
        "Kome overview reads machine-readable theme state"
    contains config/quickshell/SettingsPages/KomePage.qml '["kome-wallpaper", "current"]' \
        "Kome overview reads the active wallpaper"
    contains config/quickshell/SettingsPages/KomePage.qml '["kome-theme", "preset", preset]' \
        "Kome overview applies authentic theme presets"
    contains config/quickshell/SettingsPages/KomePage.qml '["kome-theme", "set", mode]' \
        "Kome overview applies light and dark modes"
    contains config/quickshell/SettingsPages/KomePage.qml '["kome-wallpaper", "picker"]' \
        "Kome overview opens the visual wallpaper picker"
    contains config/quickshell/SettingsPages/KomePage.qml '["kome-wallpaper", "next"]' \
        "Kome overview advances the wallpaper"
    contains config/quickshell/SettingsPages/KomePage.qml '["kome-wallpaper", "random"]' \
        "Kome overview selects a random wallpaper"
else
    fail "Kome overview page exists"
fi

ln -s "$ROOT/scripts/kome-theme" "$iso_home/.local/bin/kome-theme"
mkdir -p "$iso_home/.config/matugen/templates"
cp "$ROOT/config/matugen/config.toml" "$iso_home/.config/matugen/config.toml"
cp "$ROOT"/config/matugen/templates/* "$iso_home/.config/matugen/templates/"
for command in hyprctl notify-send sleep; do
    cat >"$iso_home/.local/bin/$command" <<'EOF'
#!/usr/bin/env sh
exit 0
EOF
done
chmod +x "$iso_home/.local/bin/hyprctl" "$iso_home/.local/bin/notify-send" "$iso_home/.local/bin/sleep"
if HOME="$iso_home" XDG_CONFIG_HOME="$iso_home/.config" \
    PATH="$iso_home/.local/bin:/usr/bin:/bin" \
    "$iso_home/.local/bin/kome-theme" preset tokyo-night --no-reload >/dev/null 2>&1 \
    && [[ "$(cat "$iso_home/.config/kome/theme/preset" 2>/dev/null)" == "tokyo-night" ]] \
    && [[ -f "$iso_home/.config/quickshell/Theme.qml" ]]; then
    pass "kome-theme applies presets through installed symlinks"
else
    fail "kome-theme applies presets through installed symlinks"
fi
contains scripts/kome-theme 'readlink -f -- "${BASH_SOURCE[0]}"' \
    "kome-theme resolves its repo root through symlinks"
contains scripts/kome-wallpaper 'readlink -f -- "${BASH_SOURCE[0]}"' \
    "kome-wallpaper resolves its repo root through symlinks"

if [[ "$FAIL" -eq 0 ]]; then
    echo "=== kome-hub: all pass ==="
else
    echo "=== kome-hub: FAILURES ==="
fi
exit "$FAIL"
