#!/usr/bin/env bash

wallpaper_path="$HOME/Pictures/wallpapers"
wallpapers_folder="$HOME/Pictures/wallpapers"

current_wallpaper=$(readlink -f "$wallpaper_path/wallpaper" 2> /dev/null)
echo "current: $current_wallpaper"

mapfile -t wallpaper_list < <(find "$wallpapers_folder" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) ! -name "wallpaper")
wallpaper_count=${#wallpaper_list[@]}
echo "total wallpapers (including subfolders): $wallpaper_count"

while true; do
    wallpaper_file="${wallpaper_list[RANDOM % wallpaper_count]}"

    if [[ "$wallpaper_file" != "$current_wallpaper" ]]; then
        break
    fi
done

echo "selected: $wallpaper_file"
ln -sf "$wallpaper_file" "$wallpaper_path/wallpaper"
wall-change "$wallpaper_path/wallpaper"
