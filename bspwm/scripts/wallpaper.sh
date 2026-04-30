#!/bin/bash

WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/Pictures/wallpapers}"
INTERVAL="${WALLPAPER_INTERVAL:-600}"
LOCK_FILE="${XDG_RUNTIME_DIR:-/tmp}/bspwm-wallpaper-${UID}.lock"
SLEEP_PID=""

exec 9>"$LOCK_FILE" || exit 1
flock -n 9 || exit 0

cleanup() {
    if [ -n "$SLEEP_PID" ]; then
        kill "$SLEEP_PID" 2>/dev/null
    fi
    exit 0
}

trap cleanup INT TERM

while true; do
    WALLPAPER=$(find -L "$WALLPAPER_DIR" -type f 2>/dev/null | shuf -n 1)
    [ -n "$WALLPAPER" ] && nitrogen --set-zoom-fill "$WALLPAPER" --save

    ( exec 9>&-; sleep "$INTERVAL" ) &
    SLEEP_PID=$!
    wait "$SLEEP_PID"
    SLEEP_PID=""
done
