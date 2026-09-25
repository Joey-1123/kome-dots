#!/usr/bin/env bash

STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/waybar-active-player"

while read -r PLAYER; do
    if [[ "$(playerctl --player="$PLAYER" status 2>/dev/null)" == "Playing" ]]; then
        printf '%s' "$PLAYER" >"$STATE_FILE"
        printf '%s\n' "$PLAYER"
        exit 0
    fi
done < <(playerctl -l 2>/dev/null)

if [[ -f "$STATE_FILE" ]]; then
    PLAYER="$(cat "$STATE_FILE")"
    if playerctl --player="$PLAYER" status >/dev/null 2>&1; then
        printf '%s\n' "$PLAYER"
        exit 0
    fi
    rm -f "$STATE_FILE"
fi

exit 1
