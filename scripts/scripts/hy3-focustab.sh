#!/usr/bin/env bash
# Cycle hy3 tabs with wrap-around. Usage: hy3-focustab r|l
DIR="${1:-r}"

BEFORE=$(hyprctl activewindow -j | jq -r '.address')
hyprctl dispatch hy3:focustab "$DIR"
AFTER=$(hyprctl activewindow -j | jq -r '.address')

if [ "$BEFORE" = "$AFTER" ]; then
    OPPOSITE=$([ "$DIR" = "r" ] && echo "l" || echo "r")
    while true; do
        CURR=$(hyprctl activewindow -j | jq -r '.address')
        hyprctl dispatch hy3:focustab "$OPPOSITE"
        NEXT=$(hyprctl activewindow -j | jq -r '.address')
        [ "$CURR" = "$NEXT" ] && break
    done
fi
