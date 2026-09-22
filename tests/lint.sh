#!/usr/bin/env bash
# lint.sh — run shellcheck and basic syntax checks.

set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=== shellcheck ==="
if command -v shellcheck >/dev/null 2>&1; then
    shellcheck -x "$ROOT"/install.sh
    shellcheck -x "$ROOT"/install/main.sh
    shellcheck -x "$ROOT"/install/lib/*.sh
    shellcheck -x "$ROOT"/scripts/kome-*
    shellcheck -x "$ROOT"/tests/*.sh
    shellcheck -x "$ROOT"/config/quickshell/hyprquickpaper/*.sh
else
    echo "shellcheck not installed, skipping"
fi

echo ""
echo "=== bash -n ==="
bash -n "$ROOT/install.sh"
bash -n "$ROOT/install/main.sh"
for f in "$ROOT"/install/lib/*.sh; do bash -n "$f"; done
for f in "$ROOT"/scripts/kome-*; do bash -n "$f"; done
for f in "$ROOT"/tests/*.sh; do bash -n "$f"; done
for f in "$ROOT"/config/quickshell/hyprquickpaper/*.sh; do bash -n "$f"; done

echo ""
echo "=== lua syntax (luac -p) ==="
for f in "$ROOT"/config/hypr/*.lua "$ROOT"/config/hypr/modules/*.lua; do
    luac -p "$f" 2>&1 | sed "s#^#$f: #" || true
done

echo ""
echo "=== lint complete ==="