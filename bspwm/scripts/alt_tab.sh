#!/usr/bin/env bash
set -euo pipefail

hidden_thumb_dir="${XDG_RUNTIME_DIR:-/tmp}/alt-tab-hidden-thumbs"
hidden_meta_dir="${hidden_thumb_dir}/meta"

mkdir -p -- "$hidden_thumb_dir" "$hidden_meta_dir"

thumbnail_path() {
    printf '%s/%s.png\n' "$hidden_thumb_dir" "$1"
}

desktop_path() {
    printf '%s/%s.desktop\n' "$hidden_meta_dir" "$1"
}

window_title() {
    local wid="$1"
    local title

    title="$(
        xprop -id "$wid" _NET_WM_NAME WM_NAME 2>/dev/null |
            awk -F '"' '/ = "/ { print $2; exit }'
    )"

    printf '%s\n' "${title:-$wid}"
}

window_class() {
    local wid="$1"

    xprop -id "$wid" WM_CLASS 2>/dev/null |
        awk -F '"' '/ = "/ { print $(NF - 1); exit }' |
        tr '[:upper:]' '[:lower:]'
}

desktop_for_window() {
    bspc query -D -n "$1" --names 2>/dev/null || true
}

capture_window_preview() {
    local wid="$1"
    local preview_path="$2"

    if ! command -v import >/dev/null 2>&1; then
        return 0
    fi

    import -silent -window "$wid" "$preview_path" >/dev/null 2>&1 || rm -f -- "$preview_path"
}

hide_window() {
    local wid preview_path desktop meta_path

    wid="${1:-$(bspc query -N -n focused.window 2>/dev/null || true)}"

    if [[ -z "$wid" ]]; then
        exit 0
    fi

    preview_path="$(thumbnail_path "$wid")"
    meta_path="$(desktop_path "$wid")"
    desktop="$(desktop_for_window "$wid")"

    if [[ -n "$desktop" ]]; then
        printf '%s\n' "$desktop" > "$meta_path"
    fi

    capture_window_preview "$wid" "$preview_path"
    bspc node "$wid" -g hidden=on
}

restore_window() {
    local wid desktop preview_path meta_path

    wid="${1:-}"

    if [[ -z "$wid" ]]; then
        exit 0
    fi

    preview_path="$(thumbnail_path "$wid")"
    meta_path="$(desktop_path "$wid")"
    desktop=""

    if [[ -f "$meta_path" ]]; then
        desktop="$(<"$meta_path")"
    fi

    if [[ -z "$desktop" ]]; then
        desktop="$(desktop_for_window "$wid")"
    fi

    bspc node "$wid" -g hidden=off

    if [[ -n "$desktop" ]]; then
        bspc node "$wid" -d "$desktop" >/dev/null 2>&1 || true
        bspc desktop "$desktop" -f >/dev/null 2>&1 || true
    fi

    bspc node "$wid" -f
    rm -f -- "$preview_path" "$meta_path"
}

focus_window() {
    local wid="$1"
    local desktop

    if [[ -z "$wid" ]]; then
        exit 0
    fi

    desktop="$(desktop_for_window "$wid")"

    if [[ -n "$desktop" ]]; then
        bspc desktop "$desktop" -f >/dev/null 2>&1 || true
    fi

    bspc node "$wid" -f
}

show_last_hidden_window() {
    local wid

    wid="$(bspc query -N -n '.window.hidden' 2>/dev/null | tail -n1 || true)"

    if [[ -z "$wid" ]]; then
        exit 0
    fi

    restore_window "$wid"
}

show_combined_menu() {
    local -a visible_wids=()
    local -a hidden_wids=()
    local -a actions=()
    local -a wids=()
    local wid title class desktop preview_path display meta icon
    local screen_width usable_width_px per_tab_width_px max_columns columns rows menu_width_px
    local total_count menu_input_file selected_index index

    while IFS= read -r wid; do
        [[ -n "$wid" ]] && visible_wids+=("$wid")
    done < <(bspc query -N -n '.window.!hidden' 2>/dev/null || true)

    while IFS= read -r wid; do
        [[ -n "$wid" ]] && hidden_wids+=("$wid")
    done < <(bspc query -N -n '.window.hidden' 2>/dev/null || true)

    total_count=$(( ${#visible_wids[@]} + ${#hidden_wids[@]} ))

    if (( total_count < 1 )); then
        exit 0
    fi

    screen_width="$(xwininfo -root 2>/dev/null | awk '/Width:/ { print $2; exit }' || true)"
    screen_width="${screen_width:-1920}"

    if ! [[ "$screen_width" =~ ^[0-9]+$ ]] || (( screen_width < 640 )); then
        screen_width=1920
    fi

    usable_width_px=$((screen_width - 96))
    per_tab_width_px=$((350 + 12))
    max_columns=$((usable_width_px / per_tab_width_px))

    if (( max_columns < 1 )); then
        max_columns=1
    fi

    columns=$total_count

    if (( columns > max_columns )); then
        columns=$max_columns
    fi

    rows=$(((total_count + columns - 1) / columns))
    menu_width_px=$((columns * 350))
    menu_width_px=$((menu_width_px + (columns - 1) * 12))
    menu_width_px=$((menu_width_px + 36 + 4))

    menu_input_file="$(mktemp)"
    index=0

    for wid in "${visible_wids[@]}"; do
        title="$(window_title "$wid")"
        class="$(window_class "$wid")"
        desktop="$(desktop_for_window "$wid")"
        preview_path="$(thumbnail_path "$wid")"
        display="$title"
        meta="${title} ${class} ${desktop}"
        icon=""

        capture_window_preview "$wid" "$preview_path"

        if [[ -s "$preview_path" ]]; then
            icon="$preview_path"
        elif [[ -n "$class" ]]; then
            icon="$class"
        fi

        printf '%s' "$display" >> "$menu_input_file"
        printf '\0meta\x1f%s' "$meta" >> "$menu_input_file"

        if [[ -n "$icon" ]]; then
            printf '\x1ficon\x1f%s' "$icon" >> "$menu_input_file"
        fi

        printf '\n' >> "$menu_input_file"
        actions[index]="visible"
        wids[index]="$wid"
        ((index += 1))
    done

    for wid in "${hidden_wids[@]}"; do
        title="$(window_title "$wid")"
        class="$(window_class "$wid")"
        desktop="$(desktop_for_window "$wid")"
        preview_path="$(thumbnail_path "$wid")"
        display="[Hidden] ${title}"
        meta="${title} ${class} ${desktop} hidden"
        icon=""

        if [[ -s "$preview_path" ]]; then
            icon="$preview_path"
        elif [[ -n "$class" ]]; then
            icon="$class"
        fi

        printf '%s' "$display" >> "$menu_input_file"
        printf '\0meta\x1f%s\x1factive\x1ftrue' "$meta" >> "$menu_input_file"

        if [[ -n "$icon" ]]; then
            printf '\x1ficon\x1f%s' "$icon" >> "$menu_input_file"
        fi

        printf '\n' >> "$menu_input_file"
        actions[index]="hidden"
        wids[index]="$wid"
        ((index += 1))
    done

    selected_index="$(
        rofi \
            -dmenu \
            -format i \
            -no-custom \
            -theme "$HOME/.config/rofi/alt-tab.rasi" \
            -theme-str "window { width: ${menu_width_px}px; } listview { columns: ${columns}; lines: ${rows}; }" \
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
            -kb-row-up "Alt+ISO_Left_Tab,Alt+Up" \
            < "$menu_input_file" || true
    )"

    rm -f -- "$menu_input_file"

    if ! [[ "$selected_index" =~ ^[0-9]+$ ]]; then
        exit 0
    fi

    case "${actions[selected_index]}" in
        visible)
            focus_window "${wids[selected_index]}"
            ;;
        hidden)
            restore_window "${wids[selected_index]}"
            ;;
    esac
}

case "${1:-}" in
    --hide)
        hide_window "${2:-}"
        exit 0
        ;;
    --restore)
        restore_window "${2:-}"
        exit 0
        ;;
    --show-last)
        show_last_hidden_window
        exit 0
        ;;
esac

tab_count="$(bspc query -N -n '.window.!hidden' 2>/dev/null | awk 'END { print NR }' || true)"
tab_count="${tab_count:-0}"

if (( tab_count < 1 )); then
    tab_count=1
fi

hidden_tab_count="$(bspc query -N -n '.window.hidden' 2>/dev/null | awk 'END { print NR }' || true)"
hidden_tab_count="${hidden_tab_count:-0}"

if (( hidden_tab_count > 0 )); then
    show_combined_menu
    exit 0
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
