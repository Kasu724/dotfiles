#!/usr/bin/env bash
set -euo pipefail

dotfiles_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
backup_dir="${BACKUP_DIR:-$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)}"

install_packages=1
link_bashrc=0
dry_run=0
backup_created=0

apt_packages=(
    bspwm
    sxhkd
    polybar
    rofi
    picom
    nitrogen
    python3
    xfce4-settings
    xfce4-terminal
    pavucontrol
    network-manager-gnome
    flameshot
    imagemagick
    x11-utils
    fontconfig
    thunar
    i3lock
    pulseaudio-utils
    psmisc
    util-linux
)

optional_apt_packages=(
    google-chrome-stable
    code
    elementary-xfce-icon-theme
)

required_commands=(
    bspc
    sxhkd
    polybar
    rofi
    picom
    nitrogen
    python3
    xfsettingsd
    xfce4-terminal
    pavucontrol
    nm-connection-editor
    flameshot
    import
    xprop
    xwininfo
    fc-cache
    flock
    pactl
    killall
    thunar
)

usage() {
    cat <<EOF
Usage: ./install.sh [options]

Install this bspwm desktop setup and link the dotfiles into your home directory.

Options:
  --skip-packages   Do not install apt packages
  --link-bashrc     Also replace ~/.bashrc with a symlink to this repo's .bashrc
  --dry-run         Print commands without changing the system
  -h, --help        Show this help

Existing files and directories at symlink targets are moved to:
  $backup_dir
EOF
}

log() {
    printf '==> %s\n' "$*"
}

warn() {
    printf 'warning: %s\n' "$*" >&2
}

die() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

run() {
    if (( dry_run )); then
        printf '+'
        printf ' %q' "$@"
        printf '\n'
        return 0
    fi

    "$@"
}

parse_args() {
    while (($#)); do
        case "$1" in
            --skip-packages)
                install_packages=0
                ;;
            --link-bashrc)
                link_bashrc=1
                ;;
            --dry-run)
                dry_run=1
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                die "unknown option: $1"
                ;;
        esac
        shift
    done
}

install_apt_packages() {
    local sudo_cmd=()
    local optional_available=()
    local optional_missing=()
    local package

    if ! command -v apt-get >/dev/null 2>&1; then
        warn "apt-get was not found; skipping package installation"
        warn "Install these packages manually: ${apt_packages[*]}"
        return 0
    fi

    if (( EUID != 0 )); then
        command -v sudo >/dev/null 2>&1 || die "sudo is required to install packages"
        sudo_cmd=(sudo)
    fi

    log "Updating apt package lists"
    run "${sudo_cmd[@]}" apt-get update

    log "Installing required apt packages"
    run "${sudo_cmd[@]}" apt-get install -y "${apt_packages[@]}"

    for package in "${optional_apt_packages[@]}"; do
        if apt-cache show "$package" >/dev/null 2>&1; then
            optional_available+=("$package")
        else
            optional_missing+=("$package")
        fi
    done

    if ((${#optional_available[@]})); then
        log "Installing optional apt packages available in your repositories"
        run "${sudo_cmd[@]}" apt-get install -y "${optional_available[@]}"
    fi

    if ((${#optional_missing[@]})); then
        warn "optional packages not found in enabled apt repositories: ${optional_missing[*]}"
    fi
}

ensure_backup_dir() {
    if (( backup_created )); then
        return 0
    fi

    run mkdir -p "$backup_dir"
    backup_created=1
}

link_item() {
    local source="$1"
    local target="$2"
    local backup_target
    local target_parent

    [[ -e "$source" ]] || die "missing source: $source"

    target_parent="$(dirname -- "$target")"
    run mkdir -p "$target_parent"

    if [[ -L "$target" ]] && [[ "$(readlink -- "$target")" == "$source" ]]; then
        log "Already linked: $target"
        return 0
    fi

    if [[ -e "$target" || -L "$target" ]]; then
        ensure_backup_dir
        backup_target="$backup_dir/$(basename -- "$target")"
        if [[ -e "$backup_target" || -L "$backup_target" ]]; then
            backup_target="$backup_target.$(date +%s)"
        fi
        log "Backing up existing target: $target"
        run mv -- "$target" "$backup_target"
    fi

    log "Linking $target"
    run ln -s "$source" "$target"
}

link_dotfiles() {
    log "Creating config and asset symlinks"

    link_item "$dotfiles_dir/bspwm" "$HOME/.config/bspwm"
    link_item "$dotfiles_dir/picom" "$HOME/.config/picom"
    link_item "$dotfiles_dir/polybar" "$HOME/.config/polybar"
    link_item "$dotfiles_dir/rofi" "$HOME/.config/rofi"
    link_item "$dotfiles_dir/sxhkd" "$HOME/.config/sxhkd"
    link_item "$dotfiles_dir/colors.txt" "$HOME/.config/colors.txt"

    link_item "$dotfiles_dir/wallpapers" "$HOME/Pictures/wallpapers"
    link_item "$dotfiles_dir/rofi_images" "$HOME/Pictures/rofi_images"
    link_item "$dotfiles_dir/fonts" "$HOME/.local/share/fonts/dotfiles-fonts"

    if (( link_bashrc )); then
        link_item "$dotfiles_dir/.bashrc" "$HOME/.bashrc"
    else
        log "Skipping ~/.bashrc; pass --link-bashrc to link it"
    fi
}

prepare_scripts() {
    log "Ensuring local scripts are executable"
    run chmod +x "$dotfiles_dir/bspwm/bspwmrc"
    run chmod +x "$dotfiles_dir/bspwm/scripts/alt_tab.sh"
    run chmod +x "$dotfiles_dir/bspwm/scripts/gradient.py"
    run chmod +x "$dotfiles_dir/bspwm/scripts/picom_launcher.sh"
    run chmod +x "$dotfiles_dir/bspwm/scripts/polybar_launcher.sh"
    run chmod +x "$dotfiles_dir/bspwm/scripts/rofi_launcher.sh"
    run chmod +x "$dotfiles_dir/bspwm/scripts/rofi_powermenu.sh"
    run chmod +x "$dotfiles_dir/bspwm/scripts/wallpaper.sh"
}

refresh_generated_files() {
    if command -v fc-cache >/dev/null 2>&1 || (( dry_run )); then
        log "Refreshing font cache"
        run fc-cache -fv "$HOME/.local/share/fonts"
    else
        warn "fc-cache is missing; font cache was not refreshed"
    fi

    if command -v python3 >/dev/null 2>&1 || (( dry_run )); then
        log "Regenerating Polybar and Rofi color files"
        run python3 "$dotfiles_dir/bspwm/scripts/gradient.py"
    else
        warn "python3 is missing; color files were not regenerated"
    fi
}

check_commands() {
    local missing=()
    local command_name

    for command_name in "${required_commands[@]}"; do
        if ! command -v "$command_name" >/dev/null 2>&1; then
            missing+=("$command_name")
        fi
    done

    if ((${#missing[@]})); then
        warn "missing commands after install: ${missing[*]}"
    fi

    if ! command -v betterlockscreen >/dev/null 2>&1 &&
        ! command -v i3lock-color >/dev/null 2>&1 &&
        ! command -v i3lock >/dev/null 2>&1 &&
        ! command -v slock >/dev/null 2>&1 &&
        ! command -v xscreensaver-command >/dev/null 2>&1; then
        warn "no supported lock command found; install betterlockscreen, i3lock-color, i3lock, slock, or xscreensaver"
    fi
}

main() {
    parse_args "$@"

    if (( install_packages )); then
        install_apt_packages
    else
        log "Skipping package installation"
    fi

    prepare_scripts
    link_dotfiles
    refresh_generated_files
    check_commands

    log "Install complete"
    if (( backup_created )); then
        printf 'Backups were saved in: %s\n' "$backup_dir"
    fi
    printf 'Start or restart your bspwm session to use the setup.\n'
}

main "$@"
