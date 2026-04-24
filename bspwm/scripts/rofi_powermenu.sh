#!/usr/bin/env bash
set -euo pipefail

# Theme
theme="$HOME/.config/rofi/powermenu.rasi"
confirm_open_delay='0.12'

confirm_theme_override='
configuration {
    hover-select: true;
}

window {
    width: 240px;
}

mainbox {
    children: [ "message", "listview" ];
}

listview {
    columns: 2;
    lines: 1;
    spacing: 18px;
    margin: 20px;
}

element {
    children: [ "element-text" ];
    spacing: 0px;
    width: 120px;
    padding: 16px 14px;
}

element-text {
    font: "JetBrainsMono Nerd Font 26";
    horizontal-align: 0.5;
}

textbox {
    border-radius: 10px 10px 0px 0px;
    horizontal-align: 0.5;
}
'

# System Info
get_last_login() {
    local raw

    raw=$(last -Fw "$USER" 2>/dev/null | awk 'NR==1 {print $5, $6, $7, $8}' || true)

    if [[ -z "$raw" ]]; then
        printf '%s' "Unavailable"
        return
    fi

    date -d "$raw" +"%B %d, %I:%M %p" 2>/dev/null || printf '%s' "$raw"
}

get_uptime() {
    local raw

    raw=$(uptime -p 2>/dev/null || true)

    if [[ -z "$raw" ]]; then
        printf '%s' "Unavailable"
    fi

    printf '%s' "$raw" | sed -e 's/^up //; s/ hours\?/ hrs/; s/ minutes\?/ mins/'
}

last_login="$(get_last_login)"
uptime_text="$(get_uptime)"
host="$(hostname)"

# Options
lock=' '
logout=' '
suspend=' '
reboot=' '
shutdown=' '
yes=' '
no='  '

# Rofi CMD
rofi_cmd() {
    rofi -dmenu \
        -p "󰟪 $USER@$host" \
        -mesg "󱫐 Last Login: $last_login     󰔚 Uptime: $uptime_text" \
        -config "$theme" \
        -theme "$HOME/.config/rofi/powermenu.rasi"
}

# Confirmation CMD
confirm_cmd() {
    # Let the initial click finish so the confirmation rofi does not inherit it.
    sleep "$confirm_open_delay"

    rofi -dmenu \
        -p "Confirmation" \
        -mesg "$1" \
        -config "$theme" \
        -theme-str "$confirm_theme_override"
}

# Ask for confirmation
confirm_exit() {
    printf '%s\n' "$yes" "$no" | confirm_cmd "$1"
}

# Pass variables to rofi dmenu
run_rofi() {
    printf '%s\n' "$lock" "$logout" "$suspend" "$reboot" "$shutdown" | rofi_cmd
}

lock_screen() {
    if command -v betterlockscreen >/dev/null 2>&1; then
        exec betterlockscreen -l
    elif command -v i3lock-color >/dev/null 2>&1; then
        exec i3lock-color
    elif command -v i3lock >/dev/null 2>&1; then
        exec i3lock
    elif command -v slock >/dev/null 2>&1; then
        exec slock
    elif command -v xscreensaver-command >/dev/null 2>&1; then
        exec xscreensaver-command -lock
    elif command -v loginctl >/dev/null 2>&1; then
        exec loginctl lock-session
    fi

    return 1
}

have_lock_command() {
    command -v betterlockscreen >/dev/null 2>&1 ||
        command -v i3lock-color >/dev/null 2>&1 ||
        command -v i3lock >/dev/null 2>&1 ||
        command -v slock >/dev/null 2>&1 ||
        command -v xscreensaver-command >/dev/null 2>&1
}

# Execute Command
run_cmd() {
    local action="$1"
    local prompt="$2"
    local selected

    selected="$(confirm_exit "$prompt" || true)"

    [[ "$selected" == "$yes" ]] || exit 0

    if [[ "$action" == '--shutdown' ]]; then
        exec systemctl poweroff
    elif [[ "$action" == '--reboot' ]]; then
        exec systemctl reboot
    elif [[ "$action" == '--suspend' ]]; then
        if command -v loginctl >/dev/null 2>&1; then
            loginctl lock-session || true
            sleep 1
        elif have_lock_command; then
            lock_screen >/dev/null 2>&1 &
            sleep 1
        fi

        exec systemctl suspend
    elif [[ "$action" == '--logout' ]]; then
        if command -v bspc >/dev/null 2>&1; then
            exec bspc quit
        elif command -v xfce4-session-logout >/dev/null 2>&1; then
            exec xfce4-session-logout --logout --fast
        elif command -v loginctl >/dev/null 2>&1 && [[ -n "${XDG_SESSION_ID:-}" ]]; then
            exec loginctl terminate-session "$XDG_SESSION_ID"
        fi
    fi
}

# Actions
chosen="$(run_rofi || true)"
[[ -n "$chosen" ]] || exit 0

case "$chosen" in
    "$lock")
        lock_screen
        ;;
    "$logout")
        run_cmd --logout "Log out?"
        ;;
    "$suspend")
        run_cmd --suspend "Suspend?"
        ;;
    "$reboot")
        run_cmd --reboot "Reboot?"
        ;;
    "$shutdown")
        run_cmd --shutdown "Power off?"
        ;;
esac
