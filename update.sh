#!/usr/bin/env bash
set -euo pipefail

dotfiles_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
reload_desktop=0

usage() {
    cat <<EOF
Usage: ./update.sh [options]

Pull the latest dotfiles from this checkout's upstream branch and refresh the
local symlinks and generated files.

Options:
  --reload    Reload the running bspwm desktop after updating
  -h, --help  Show this help

Local changes are never stashed or discarded. The update stops if they conflict
with incoming changes.
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

parse_args() {
    while (($#)); do
        case "$1" in
            --reload)
                reload_desktop=1
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

pull_dotfiles() {
    local upstream

    command -v git >/dev/null 2>&1 || die "git is required to update the dotfiles"
    git -C "$dotfiles_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1 ||
        die "$dotfiles_dir is not a Git checkout"

    upstream="$(
        git -C "$dotfiles_dir" rev-parse \
            --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null
    )" || die "the current branch has no upstream; configure one before updating"

    if [[ -n "$(git -C "$dotfiles_dir" status --porcelain)" ]]; then
        warn "local changes detected; they will be kept"
    fi

    log "Pulling updates from $upstream"
    git -C "$dotfiles_dir" pull --ff-only
}

refresh_installation() {
    log "Refreshing links and generated files"
    "$dotfiles_dir/install.sh" --skip-packages
}

reload_running_desktop() {
    local current_uid
    current_uid="$(id -u)"

    if pgrep -u "$current_uid" -x sxhkd >/dev/null; then
        log "Reloading sxhkd"
        pkill -USR1 -u "$current_uid" -x sxhkd
    fi

    if pgrep -u "$current_uid" -x bspwm >/dev/null; then
        if command -v bspc >/dev/null 2>&1; then
            log "Reloading bspwm and its session components"
            bspc wm -r
        else
            warn "bspwm is running, but bspc is unavailable; restart the session to apply its config"
        fi
        return
    fi

    if pgrep -u "$current_uid" -x picom >/dev/null; then
        log "Restarting picom"
        "$dotfiles_dir/bspwm/scripts/picom_launcher.sh" >/dev/null 2>&1 &
    fi

    if pgrep -u "$current_uid" -x polybar >/dev/null; then
        log "Restarting Polybar"
        "$dotfiles_dir/bspwm/scripts/polybar_launcher.sh" >/dev/null 2>&1 &
    fi
}

main() {
    parse_args "$@"
    pull_dotfiles
    refresh_installation

    if (( reload_desktop )); then
        reload_running_desktop
    else
        log "Files updated; pass --reload to also reload the running desktop"
    fi
}

main "$@"
