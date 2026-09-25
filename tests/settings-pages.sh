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
component_contract SettingsSearch.qml "shared keyboard search field"
component_contract NetworkHero.qml "shared active network summary"
component_contract ConfirmDialog.qml "shared confirmation overlay"
component_contract StorageUsage.qml "shared filesystem usage visualization"
component_contract ConfigService.qml "shared config launcher service"
component_contract ShortcutService.qml "shared keybind reference service"

if [[ -f "$ROOT/config/quickshell/SettingsPage.qml" ]]; then
    if grep -Fq 'bottomPadding: 18' "$ROOT/config/quickshell/SettingsPage.qml"; then
        pass "shared page reserves bottom scroll space"
    else
        fail "shared page reserves bottom scroll space"
    fi
    if grep -Fq 'scroll.contentY = 0' "$ROOT/config/quickshell/SettingsPage.qml"; then
        pass "shared pages open at their top edge"
    else
        fail "shared pages open at their top edge"
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

display_page="$ROOT/config/quickshell/SettingsPages/MonitorsPage.qml"
display_service="$ROOT/config/quickshell/DisplayService.qml"
if grep -Fq 'SettingsPage {' "$display_page" \
    && grep -Fq 'DisplayService {' "$display_page" \
    && [[ "$(wc -l < "$display_page")" -le 260 ]]; then
    pass "Display page separates monitor control from its UI"
else
    fail "Display page separates monitor control from its UI"
fi
if grep -Fq 'availableModes' "$display_page" \
    && ! grep -Fq '1920x1080' "$display_page"; then
    pass "Display page uses live monitor modes"
else
    fail "Display page uses live monitor modes"
fi
if grep -Fq 'monitors[0]' "$display_page"; then
    fail "Display actions do not target the first monitor implicitly"
else
    pass "Display actions do not target the first monitor implicitly"
fi
if grep -Fq 'function isCurrentMode(mode)' "$display_page" \
    && grep -Fq 'parseFloat(rate)' "$display_page"; then
    pass "Display selects exactly one live refresh mode"
else
    fail "Display selects exactly one live refresh mode"
fi
if grep -Fq 'selectedMonitor' "$display_page" \
    && [[ "$(grep -Fc 'SettingsSection {' "$display_page")" -ge 4 ]]; then
    pass "Display page exposes selection, mode, layout, and comfort controls"
else
    fail "Display page exposes selection, mode, layout, and comfort controls"
fi
if grep -Fq 'hl.monitor' "$display_service" \
    && grep -Fq 'Quickshell' "$display_service"; then
    pass "Display service uses the Hyprland Lua monitor API"
else
    fail "Display service uses the Hyprland Lua monitor API"
fi
if grep -Fq 'page.selectedMonitor ? page.selectedMonitor.mirrorOf' "$display_page"; then
    pass "Display mirror text is null-safe"
else
    fail "Display mirror text is null-safe"
fi
if grep -Fq 'id: nightlightLoad' "$display_service" \
    && ! grep -Fq 'FileView {' "$display_service"; then
    pass "Display night-light persistence avoids missing-file warnings"
else
    fail "Display night-light persistence avoids missing-file warnings"
fi

if [[ -f "$ROOT/config/quickshell/SettingsSearch.qml" ]]; then
    if grep -Fq 'Keys.onEscapePressed' "$ROOT/config/quickshell/SettingsSearch.qml" \
        && grep -Fq 'TextInput' "$ROOT/config/quickshell/SettingsSearch.qml"; then
        pass "shared search supports keyboard focus and clearing"
    else
        fail "shared search supports keyboard focus and clearing"
    fi
fi

network_page="$ROOT/config/quickshell/SettingsPages/NetworkPage.qml"
network_service="$ROOT/config/quickshell/NetworkService.qml"
if grep -Fq 'SettingsPage {' "$network_page" \
    && grep -Fq 'NetworkService {' "$network_page" \
    && [[ "$(wc -l < "$network_page")" -le 260 ]]; then
    pass "Network page separates network control from its UI"
else
    fail "Network page separates network control from its UI"
fi
if grep -Fq 'SettingsSearch {' "$network_page" \
    && [[ "$(grep -Fc 'SettingsSection {' "$network_page")" -ge 4 ]]; then
    pass "Network page exposes status, Wi-Fi, search, and wired sections"
else
    fail "Network page exposes status, Wi-Fi, search, and wired sections"
fi
if grep -Fq '"device", "wifi", "connect", ssid, "password", password' "$network_service"; then
    pass "Network service passes Wi-Fi credentials as separate arguments"
else
    fail "Network service passes Wi-Fi credentials as separate arguments"
fi
if grep -Fq 'property string password' "$network_service" \
    || grep -Fq 'statusText.*password' "$network_page"; then
    fail "Network page does not retain or display Wi-Fi passwords"
else
    pass "Network page does not retain or display Wi-Fi passwords"
fi
if grep -Eq 'contentRightMargin|property string monoFont' "$network_page" \
    || grep -Eq '#[0-9a-fA-F]{6,8}' "$network_page"; then
    fail "Network page uses shared tokens without legacy margins"
else
    pass "Network page uses shared tokens without legacy margins"
fi

bluetooth_page="$ROOT/config/quickshell/SettingsPages/BluetoothPage.qml"
bluetooth_service="$ROOT/config/quickshell/BluetoothService.qml"
if grep -Fq 'SettingsPage {' "$bluetooth_page" \
    && grep -Fq 'BluetoothService {' "$bluetooth_page" \
    && [[ "$(wc -l < "$bluetooth_page")" -le 260 ]]; then
    pass "Bluetooth page separates adapter control from its UI"
else
    fail "Bluetooth page separates adapter control from its UI"
fi
if grep -Fq 'SettingsSearch {' "$bluetooth_page" \
    && grep -Fq 'adapter.devices.values.filter' "$bluetooth_service" \
    && grep -Fq 'pairedDevices' "$bluetooth_service" \
    && grep -Fq 'availableDevices' "$bluetooth_service"; then
    pass "Bluetooth page separates paired and available devices"
else
    fail "Bluetooth page separates paired and available devices"
fi
if grep -Fq 'ConfirmDialog {' "$bluetooth_page" \
    && grep -Fq $'z: 1000\n    anchors.fill: parent' "$ROOT/config/quickshell/ConfirmDialog.qml" \
    && grep -Fq 'function forget(device)' "$bluetooth_service"; then
    pass "Bluetooth forget requires shared confirmation"
else
    fail "Bluetooth forget requires shared confirmation"
fi
if grep -Fq 'onDevicesChanged' "$bluetooth_page" \
    || grep -Fq 'removed-bluetooth-devices.json' "$bluetooth_page" \
    || grep -Fq 'FileView {' "$bluetooth_page"; then
    fail "Bluetooth page removes invalid handlers and missing-state warnings"
else
    pass "Bluetooth page removes invalid handlers and missing-state warnings"
fi
if grep -Eq '#[0-9a-fA-F]{6,8}|contentRightMargin' "$bluetooth_page"; then
    fail "Bluetooth page uses shared semantic tokens"
else
    pass "Bluetooth page uses shared semantic tokens"
fi

storage_page="$ROOT/config/quickshell/SettingsPages/StoragePage.qml"
storage_service="$ROOT/config/quickshell/StorageService.qml"
if grep -Fq 'SettingsPage {' "$storage_page" \
    && grep -Fq 'StorageService {' "$storage_page" \
    && grep -Fq 'StorageUsage {' "$storage_page" \
    && [[ "$(wc -l < "$storage_page")" -le 260 ]]; then
    pass "Storage page separates collection from its UI"
else
    fail "Storage page separates collection from its UI"
fi
if grep -Fq 'ConfirmDialog {' "$storage_page" \
    && grep -Fq 'function runCleanup(key)' "$storage_service" \
    && grep -Fq 'cleanupActions' "$storage_service"; then
    pass "Storage cleanup actions use confirmation and fixed service commands"
else
    fail "Storage cleanup actions use confirmation and fixed service commands"
fi
if grep -Eq 'contentRightMargin|confirmPopup|ToolButton|color: .#[0-9a-fA-F]' "$storage_page"; then
    fail "Storage page removes legacy margins and raw destructive popup colors"
else
    pass "Storage page removes legacy margins and raw destructive popup colors"
fi
if grep -Eq 'rm -rf|paccache|journalctl|flatpak uninstall' "$storage_page"; then
    fail "Storage page does not embed destructive shell commands"
else
    pass "Storage page does not embed destructive shell commands"
fi
if grep -Fq '"df", "-P"' "$storage_service" \
    && grep -Fq 'lsblk' "$storage_service" \
    && grep -Fq 'function usageForDisk' "$storage_service"; then
    pass "Storage service reports filesystems and per-disk usage"
else
    fail "Storage service reports filesystems and per-disk usage"
fi

configs_page="$ROOT/config/quickshell/SettingsPages/ConfigsPage.qml"
config_service="$ROOT/config/quickshell/ConfigService.qml"
if grep -Fq 'SettingsPage {' "$configs_page" \
    && grep -Fq 'ConfigService {' "$configs_page" \
    && [[ "$(wc -l < "$configs_page")" -le 220 ]]; then
    pass "Configs page uses a compact searchable launcher"
else
    fail "Configs page uses a compact searchable launcher"
fi
if grep -Fq 'SettingsSearch {' "$configs_page" \
    && grep -Fq 'title: "HYPRLAND"' "$config_service" \
    && grep -Fq 'title: "WAYBAR"' "$config_service" \
    && grep -Fq 'title: "WLOGOUT"' "$config_service" \
    && grep -Fq 'Repeater {' "$configs_page"; then
    pass "Configs page groups Hyprland, Waybar, and Wlogout files"
else
    fail "Configs page groups Hyprland, Waybar, and Wlogout files"
fi
if grep -Fq 'Quickshell.execDetached' "$config_service" \
    && grep -Fq '"xdg-open"' "$config_service" \
    && grep -Fq 'function pathExists(path)' "$config_service" \
    && ! grep -Fq 'xed' "$configs_page" \
    && ! grep -Fq 'xed' "$config_service"; then
    pass "Configs service opens resolved files without hardcoded xed"
else
    fail "Configs service opens resolved files without hardcoded xed"
fi
if grep -Eq 'marginRight|sliderMarginRight|#[0-9a-fA-F]{6,8}' "$configs_page"; then
    fail "Configs page uses shared layout and semantic tokens"
else
    pass "Configs page uses shared layout and semantic tokens"
fi

shortcuts_page="$ROOT/config/quickshell/SettingsPages/ShortcutsPage.qml"
shortcut_service="$ROOT/config/quickshell/ShortcutService.qml"
if grep -Fq 'SettingsPage {' "$shortcuts_page" \
    && grep -Fq 'ShortcutService {' "$shortcuts_page" \
    && grep -Fq 'SettingsSearch {' "$shortcuts_page" \
    && grep -Fq 'EmptyState {' "$shortcuts_page"; then
    pass "Shortcuts page uses shared search and state components"
else
    fail "Shortcuts page uses shared search and state components"
fi
if grep -Fq '["kome-keybinds", "--list"]' "$shortcut_service" \
    && grep -Fq 'function filtered' "$shortcut_service" \
    && grep -Fq 'loading' "$shortcut_service"; then
    pass "Shortcuts service parses the canonical keybind list"
else
    fail "Shortcuts service parses the canonical keybind list"
fi

if [[ "$FAIL" -eq 0 ]]; then
    echo "=== settings-pages: all pass ==="
else
    echo "=== settings-pages: FAILURES ==="
fi
exit "$FAIL"
