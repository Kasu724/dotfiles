#!/bin/bash
set -e

WALLPAPER_DIR="$HOME/Pictures/rofi_images"
TARGET="$HOME/.config/rofi/image"

IMG=$(find -L "$WALLPAPER_DIR" -type f | shuf -n 1)

[ -z "$IMG" ] && exit 1

ln -sf "$IMG" "$TARGET"

exec rofi -show drun -matching fuzzy -config "$HOME/.config/rofi/config.rasi"