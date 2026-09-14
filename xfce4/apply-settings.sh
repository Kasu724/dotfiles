#!/usr/bin/env bash
set -u

failed=0

warn() {
    printf 'warning: %s\n' "$*" >&2
}

# xfconf and dconf both need a session bus. This makes the settings installable
# from a text console as well as from an existing graphical session.
if [[ -z "${DBUS_SESSION_BUS_ADDRESS:-}" &&
    -z "${DOTFILES_SETTINGS_DBUS_STARTED:-}" ]] &&
    command -v dbus-run-session >/dev/null 2>&1; then
    exec dbus-run-session -- env DOTFILES_SETTINGS_DBUS_STARTED=1 "$0" "$@"
fi

set_xfconf() {
    local channel="$1"
    local property="$2"
    local type="$3"
    local value="$4"

    if xfconf-query -c "$channel" -p "$property" >/dev/null 2>&1; then
        if ! xfconf-query -c "$channel" -p "$property" -s "$value"; then
            warn "could not set XFCE property $channel:$property"
            failed=1
        fi
    elif ! xfconf-query -c "$channel" -p "$property" -n -t "$type" -s "$value"; then
        warn "could not create XFCE property $channel:$property"
        failed=1
    fi
}

set_gsetting() {
    local schema="$1"
    local key="$2"
    local value="$3"

    if ! gsettings writable "$schema" "$key" >/dev/null 2>&1; then
        warn "GSettings key is unavailable: $schema $key"
        failed=1
        return
    fi

    if ! gsettings set "$schema" "$key" "$value"; then
        warn "could not set GSettings key: $schema $key"
        failed=1
    fi
}

if command -v xfconf-query >/dev/null 2>&1; then
    # XFCE Terminal: white text on black with 30% transparency.
    set_xfconf xfce4-terminal /background-darkness double 0.7
    set_xfconf xfce4-terminal /background-mode string TERMINAL_BACKGROUND_TRANSPARENT
    set_xfconf xfce4-terminal /color-background string '#000000000000'
    set_xfconf xfce4-terminal /color-bold string '#ffffff'
    set_xfconf xfce4-terminal /color-bold-use-default bool false
    set_xfconf xfce4-terminal /color-cursor string '#0f4999'
    set_xfconf xfce4-terminal /color-foreground string '#ffffffffffff'
    set_xfconf xfce4-terminal /color-palette string 'rgb(0,0,0);rgb(170,0,0);rgb(68,170,68);rgb(255,120,0);rgb(0,57,170);rgb(170,34,170);rgb(26,146,170);rgb(170,170,170);rgb(119,119,119);rgb(255,135,135);rgb(76,230,76);rgb(222,216,44);rgb(41,95,204);rgb(204,88,204);rgb(76,204,230);rgb(255,255,255)'
    set_xfconf xfce4-terminal /color-selection string '#163b59'
    set_xfconf xfce4-terminal /color-selection-use-default bool false
    set_xfconf xfce4-terminal /font-name string 'JetBrainsMono Nerd Font 10'
    set_xfconf xfce4-terminal /misc-cursor-blinks bool true
    set_xfconf xfce4-terminal /misc-cursor-shape string TERMINAL_CURSOR_SHAPE_BLOCK
    set_xfconf xfce4-terminal /tab-activity-color string '#0f4999'

    # Portable appearance settings from this machine. Hardware-specific display,
    # keyboard, and pointer mappings are intentionally not applied.
    set_xfconf xsettings /Net/ThemeName string Adwaita-dark
    set_xfconf xsettings /Net/IconThemeName string Adwaita
    set_xfconf xsettings /Gdk/WindowScalingFactor int 1
    set_xfconf xsettings /Gtk/ButtonImages bool true
    set_xfconf xsettings /Gtk/CursorThemeName string Adwaita
    set_xfconf xsettings /Gtk/CursorThemeSize int 16
    set_xfconf xsettings /Gtk/DecorationLayout string 'menu:minimize,maximize,close'
    set_xfconf xsettings /Gtk/DialogsUseHeader bool false
    set_xfconf xsettings /Gtk/FontName string 'Sans 10'
    set_xfconf xsettings /Gtk/MonospaceFontName string 'JetBrainsMono Nerd Font 10'
    set_xfconf xsettings /Gtk/TitlebarMiddleClick string lower
    set_xfconf xsettings /Xft/Antialias int -1
    set_xfconf xsettings /Xft/DPI int 120
    set_xfconf xsettings /Xft/Hinting int -1
    set_xfconf xsettings /Xft/HintStyle string hintnone
    set_xfconf xsettings /Xft/RGBA string none
    set_xfconf xsettings /Xfce/LastCustomDPI int 120
    set_xfconf xsettings /Xfce/SyncThemes bool false

    set_xfconf xfce4-session /general/AutoSave bool false
    set_xfconf xfce4-power-manager /xfce4-power-manager/power-button-action int 3
    set_xfconf xfce4-power-manager /xfce4-power-manager/show-tray-icon bool false
else
    warn 'xfconf-query is unavailable; XFCE settings were not applied'
    failed=1
fi

if command -v gsettings >/dev/null 2>&1; then
    # Keep GTK 3/4 and libadwaita applications aligned with XFCE's dark theme.
    set_gsetting org.gnome.desktop.interface color-scheme "'prefer-dark'"
    set_gsetting org.gnome.desktop.interface gtk-theme "'Adwaita-dark'"
    set_gsetting org.gnome.desktop.interface icon-theme "'Adwaita'"
    set_gsetting org.gnome.desktop.interface cursor-theme "'Adwaita'"
    set_gsetting org.gnome.desktop.interface cursor-size 24
    set_gsetting org.gnome.desktop.interface font-name "'Noto Sans 9'"
    set_gsetting org.gnome.desktop.interface monospace-font-name "'JetBrainsMono Nerd Font 10'"
else
    warn 'gsettings is unavailable; GTK dark-mode preferences were not applied'
    failed=1
fi

exit "$failed"
