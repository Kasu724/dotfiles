#!/bin/bash

WALLPAPER_DIR="$HOME/Pictures/wallpapers"

while true; do
    WALLPAPER=$(find -L "$WALLPAPER_DIR" -type f | shuf -n 1)
    [ -n "$WALLPAPER" ] && nitrogen --set-zoom-fill "$WALLPAPER" --save
    sleep 600
done