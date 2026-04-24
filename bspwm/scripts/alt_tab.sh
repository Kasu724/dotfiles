#!/usr/bin/env bash
set -euo pipefail

tab_count="$(bspc query -N -n '.window' 2>/dev/null | awk 'END { print NR }' || true)"
tab_count="${tab_count:-0}"

if (( tab_count < 1 )); then
    tab_count=1
fi

screen_width="$(xwininfo -root 2>/dev/null | awk '/Width:/ { print $2; exit }' || true)"
screen_width="${screen_width:-1920}"

if ! [[ "$screen_width" =~ ^[0-9]+$ ]] || (( screen_width < 640 )); then
    screen_width=1920
fi

tab_width_px=350
tab_gap_px=12
list_padding_px=36
window_frame_px=4
screen_margin_px=96

usable_width_px=$((screen_width - screen_margin_px))
per_tab_width_px=$((tab_width_px + tab_gap_px))
max_columns=$((usable_width_px / per_tab_width_px))

if (( max_columns < 1 )); then
    max_columns=1
fi

columns=$tab_count

if (( columns > max_columns )); then
    columns=$max_columns
fi

rows=$(((tab_count + columns - 1) / columns))

menu_width_px=$((columns * tab_width_px))
menu_width_px=$((menu_width_px + (columns - 1) * tab_gap_px))
menu_width_px=$((menu_width_px + list_padding_px + window_frame_px))

theme_override="window { width: ${menu_width_px}px; } listview { columns: ${columns}; lines: ${rows}; }"

exec rofi \
    -theme "$HOME/.config/rofi/alt-tab.rasi" \
    -theme-str "$theme_override" \
    -show window -show-icons -window-thumbnail \
    -show-icons \
    -steal-focus \
    -selected-row 1 \
    -matching fuzzy \
    -no-lazy-grab \
    -hover-select \
    -me-select-entry "" \
    -me-accept-entry "MousePrimary,Alt+MousePrimary" \
    -kb-cancel "Alt+Escape,Escape" \
    -kb-accept-entry "!Alt-Tab,!Alt+Alt_L,Return,!Alt_L" \
    -kb-row-down "Alt+Tab,Alt+Down" \
    -kb-row-up "Alt+ISO_Left_Tab,Alt+Up"
