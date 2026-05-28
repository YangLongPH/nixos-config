#!/usr/bin/env bash

lock_screen_folder="$HOME/Pictures/lock-screen"

if [[ ! -d "$lock_screen_folder" ]]; then
    exit 0
fi

mapfile -t images < <(find "$lock_screen_folder" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \))
count=${#images[@]}

if [[ $count -eq 0 ]]; then
    # fallback to current wallpaper
    wallpaper=$(readlink -f "$HOME/Pictures/wallpaper" 2>/dev/null)
    [[ -f "$wallpaper" ]] && ln -sf "$wallpaper" "$lock_screen_folder/current"
    exit 0
fi

current=$(readlink -f "$lock_screen_folder/current" 2>/dev/null)

while true; do
    selected="${images[RANDOM % count]}"
    if [[ "$selected" != "$current" ]] || [[ $count -eq 1 ]]; then
        break
    fi
done

ln -sf "$selected" "$lock_screen_folder/current"
