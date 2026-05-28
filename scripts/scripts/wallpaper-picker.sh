#!/usr/bin/env bash

wallpaper_path=$HOME/Pictures/wallpapers
wallpapers_folder=$HOME/Pictures/wallpapers/others
wallpaper_name="$(ls $wallpapers_folder | rofi -dmenu || pkill rofi)"

if [[ -f $wallpapers_folder/$wallpaper_name ]]; then
    ln -sf "$wallpapers_folder/$wallpaper_name" "$HOME/Pictures/wallpaper"
    wall-change "$HOME/Pictures/wallpaper"
else
    exit 1
fi
