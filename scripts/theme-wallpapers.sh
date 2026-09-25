#!/usr/bin/env bash
# theme-wallpapers.sh — generate one abstract wallpaper per curated preset,
# using that preset's own palette so the desktop and UI agree.
# Run from the repo root. Requires ImageMagick.
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
PRESETS="${ROOT}/config/matugen/presets"
OUT="${ROOT}/wallpapers"

# preset -> "bg bottom top accent"
layout() {
    case "$1" in
        gruvbox)          printf '%s' "#1d2021 #3c3836 #282828 #d79921" ;;
        catppuccin-mocha) printf '%s' "#11111b #313244 #1e1e2e #cba6f7" ;;
        tokyo-night)      printf '%s' "#16161e #292e42 #1a1b26 #7aa2f7" ;;
        *) return 1 ;;
    esac
}

for preset in gruvbox catppuccin-mocha tokyo-night; do
    read -r c0 c1 c2 accent <<<"$(layout "$preset")"
    dir="${OUT}/dark/${preset}"
    mkdir -p "$dir"

    # Diagonal gradient base.
    convert -size 1920x1080 gradient:"${c1}-${c0}" \
        -rotate 0 -distort SRT 30 \
        "${dir}/${preset}-gradient.png"

    # Concentric glow rings, screen-blended accent.
    convert -size 1920x1080 xc:"${c2}" \
        \( -size 1920x1080 radial-gradient:"${accent}"-none \) \
        -compose screen -composite \
        "${dir}/${preset}-glow.png"

    echo "generated ${preset}: ${dir}"
done
