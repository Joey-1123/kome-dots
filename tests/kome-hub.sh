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

if [[ "$FAIL" -eq 0 ]]; then
    echo "=== kome-hub: all pass ==="
else
    echo "=== kome-hub: FAILURES ==="
fi
exit "$FAIL"
