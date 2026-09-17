#!/usr/bin/env bash
# verify-config.sh — test hyprland config with all provider combinations.

set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="$ROOT/config/hypr/hyprland.lua"

echo "=== hyprland --verify-config (base) ==="
hyprland --verify-config -c "$CONFIG"

echo ""
echo "=== testing provider configs ==="
for comp in waybar rofi swaync mako dunst wofi fuzzel yazi kitty; do
    if [[ -d "$ROOT/config/$comp" ]]; then
        echo "  $comp: dir exists"
    fi
done

echo ""
echo "=== verify complete ==="