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

if [[ "$FAIL" -eq 0 ]]; then
    echo "=== settings-pages: all pass ==="
else
    echo "=== settings-pages: FAILURES ==="
fi
exit "$FAIL"
