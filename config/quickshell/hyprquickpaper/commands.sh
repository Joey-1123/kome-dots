#!/usr/bin/env bash
# kome — set wallpaper via provider-aware command

set -euo pipefail

WALLPAPER="$1"

# Use provider-aware kome-wallpaper if available, else fall back to awww
if command -v kome-wallpaper >/dev/null 2>&1; then
    kome-wallpaper set "$WALLPAPER"
else
    awww img "$WALLPAPER" -t random --transition-duration 1
fi