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

if [[ "$FAIL" -eq 0 ]]; then
    echo "=== kome-hub: all pass ==="
else
    echo "=== kome-hub: FAILURES ==="
fi
exit "$FAIL"
