#!/usr/bin/env bash
# settings-pages.sh — contracts for the shared settings page system.
set -uo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
FAIL=0

pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s\n' "$1"; FAIL=1; }

component_contract() {
    local file="$1" label="$2"
    local path="$ROOT/config/quickshell/$file"

    if [[ ! -f "$path" ]]; then
        fail "$file exists"
        return
    fi
    pass "$file exists"

    if grep -Eq '#[0-9a-fA-F]{6,8}' "$path"; then
        fail "$file uses semantic theme tokens"
    else
        pass "$file uses semantic theme tokens"
    fi
}

component_contract SettingsPage.qml "shared settings page frame"
component_contract SettingsSection.qml "shared settings section"
component_contract SettingsRow.qml "shared settings row"
component_contract MetricCard.qml "shared live metric card"
component_contract StatePill.qml "shared semantic state pill"
component_contract EmptyState.qml "shared loading/empty/error state"

if [[ -f "$ROOT/config/quickshell/SettingsPage.qml" ]]; then
    if grep -Fq 'bottomPadding: 18' "$ROOT/config/quickshell/SettingsPage.qml"; then
        pass "shared page reserves bottom scroll space"
    else
        fail "shared page reserves bottom scroll space"
    fi
    if grep -Fq 'default property alias content' "$ROOT/config/quickshell/SettingsPage.qml"; then
        pass "shared page exposes a content slot"
    else
        fail "shared page exposes a content slot"
    fi
fi

if [[ -f "$ROOT/config/quickshell/SettingsRow.qml" ]]; then
    if grep -Fq 'activeFocusOnTab: clickable' "$ROOT/config/quickshell/SettingsRow.qml" \
        && grep -Fq 'Keys.onReturnPressed' "$ROOT/config/quickshell/SettingsRow.qml"; then
        pass "clickable settings rows are keyboard accessible"
    else
        fail "clickable settings rows are keyboard accessible"
    fi
    if grep -Fq $'height: implicitHeight\n    width: parent.width' "$ROOT/config/quickshell/SettingsRow.qml"; then
        pass "settings rows fill their section slot"
    else
        fail "settings rows fill their section slot"
    fi
fi

if [[ -f "$ROOT/config/quickshell/SettingsSection.qml" ]]; then
    if grep -Fq 'onChildrenChanged: forceLayout()' "$ROOT/config/quickshell/SettingsSection.qml" \
        && grep -Fq 'body.childrenRect.height' "$ROOT/config/quickshell/SettingsSection.qml"; then
        pass "settings sections lay out slotted children"
    else
        fail "settings sections lay out slotted children"
    fi
fi

if grep -Fq 'implicitWidth: buttonContent.implicitWidth + 28' "$ROOT/config/quickshell/HubButton.qml"; then
    pass "Hub buttons size to trailing content"
else
    fail "Hub buttons size to trailing content"
fi

if [[ -f "$ROOT/config/quickshell/MetricCard.qml" ]]; then
    if grep -Fq 'property var history' "$ROOT/config/quickshell/MetricCard.qml" \
        && grep -Fq 'Repeater' "$ROOT/config/quickshell/MetricCard.qml"; then
        pass "metric cards render optional history"
    else
        fail "metric cards render optional history"
    fi
fi

if [[ -f "$ROOT/config/quickshell/EmptyState.qml" ]]; then
    if grep -Fq 'property bool loading' "$ROOT/config/quickshell/EmptyState.qml" \
        && grep -Fq 'property bool error' "$ROOT/config/quickshell/EmptyState.qml"; then
        pass "empty states distinguish loading and errors"
    else
        fail "empty states distinguish loading and errors"
    fi
fi

system_page="$ROOT/config/quickshell/SettingsPages/SystemPage.qml"
system_telemetry="$ROOT/config/quickshell/SystemTelemetry.qml"
if grep -Fq 'SettingsPage {' "$system_page"; then
    pass "System page uses the shared page frame"
else
    fail "System page uses the shared page frame"
fi
if [[ "$(grep -Fc 'MetricCard {' "$system_page")" -ge 3 ]]; then
    pass "System page leads with three live metric cards"
else
    fail "System page leads with three live metric cards"
fi
if grep -Fq 'SettingsSection {' "$system_page" \
    && grep -Fq 'SettingsRow {' "$system_page"; then
    pass "System page uses shared sections and rows"
else
    fail "System page uses shared sections and rows"
fi
if grep -Fq 'component HardwareGraph' "$system_page"; then
    fail "System page removes the legacy inline hardware graph"
else
    pass "System page removes the legacy inline hardware graph"
fi
if grep -Eq 'property int rightMargin|contentRightMargin' "$system_page"; then
    fail "System page has no page-specific right margin"
else
    pass "System page has no page-specific right margin"
fi
if grep -Fq 'interval: 2000' "$system_telemetry" \
    && grep -Fq 'interval: 5000' "$system_telemetry" \
    && [[ "$(grep -Fc 'running: true' "$system_telemetry")" -ge 2 ]]; then
    pass "System telemetry avoids one-second expensive polling"
else
    fail "System telemetry avoids one-second expensive polling"
fi
if grep -Fq 'command: ["uname", "-n"]' "$ROOT/config/quickshell/SystemTelemetry.qml" \
    || grep -Fq 'command: ["uname", "-n"]' "$system_page"; then
    pass "System identity avoids the unavailable hostname binary"
else
    fail "System identity avoids the unavailable hostname binary"
fi
if grep -Fq 'SystemTelemetry {' "$system_page" \
    && [[ "$(wc -l < "$system_page")" -le 220 ]]; then
    pass "System page separates telemetry from its compact UI"
else
    fail "System page separates telemetry from its compact UI"
fi
if grep -Fq 'Item {' "$system_telemetry" \
    && grep -Fq 'visible: false' "$system_telemetry" \
    && grep -Fq 'width: 0' "$system_telemetry"; then
    pass "System telemetry owns hidden nonvisual resources"
else
    fail "System telemetry owns hidden nonvisual resources"
fi

audio_page="$ROOT/config/quickshell/SettingsPages/SoundPage.qml"
if grep -Fq 'SettingsPage {' "$audio_page"; then
    pass "Audio page uses the shared page frame"
else
    fail "Audio page uses the shared page frame"
fi
if [[ "$(grep -Fc 'SettingsSection {' "$audio_page")" -ge 4 ]] \
    && grep -Fq 'SettingsRow {' "$audio_page"; then
    pass "Audio page separates output, input, devices, and streams"
else
    fail "Audio page separates output, input, devices, and streams"
fi
if [[ "$(grep -Fc 'EmptyState {' "$audio_page")" -ge 2 ]]; then
    pass "Audio page exposes output, input, and stream empty states"
else
    fail "Audio page exposes output, input, and stream empty states"
fi
if grep -Fq 'Pipewire.preferredDefaultAudioSink' "$audio_page" \
    && grep -Fq 'Pipewire.preferredDefaultAudioSource' "$audio_page"; then
    pass "Audio page keeps default routing controls"
else
    fail "Audio page keeps default routing controls"
fi
if grep -Eq 'property real marginRight|property int sliderMarginRight' "$audio_page" \
    || [[ "$(wc -l < "$audio_page")" -gt 240 ]]; then
    fail "Audio page uses the shared compact layout"
else
    pass "Audio page uses the shared compact layout"
fi

if [[ "$FAIL" -eq 0 ]]; then
    echo "=== settings-pages: all pass ==="
else
    echo "=== settings-pages: FAILURES ==="
fi
exit "$FAIL"
