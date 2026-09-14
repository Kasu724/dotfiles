#!/usr/bin/env bash
set -euo pipefail

dotfiles_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
backup_dir="${BACKUP_DIR:-$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)}"

install_packages=1
link_bashrc=1
dry_run=0
backup_created=0

bspwm_version='0.9.12'
rofi_version='2.0.0'
picom_version='v13'

export PATH="$HOME/.local/bin:/usr/local/bin:/snap/bin:$PATH"

apt_packages=(
    bspwm
    sxhkd
    polybar
    rofi
    picom
    feh
    nitrogen
    python3
    python3-venv
    pipx
    git
    curl
    ca-certificates
    procps
    less
    bash-completion
    libnotify-bin
    dbus-x11
    xfce4-settings
    xfce4-session
    xfce4-terminal
    xfconf
    libglib2.0-bin
    pavucontrol
    network-manager-gnome
    flameshot
    chafa
    ffmpeg
    imagemagick
    x11-utils
    fontconfig
    thunar
    i3lock
    pulseaudio-utils
    psmisc
    util-linux
    snapd
    adwaita-icon-theme
    gnome-themes-extra
    fonts-noto-core
    fonts-noto-color-emoji
)

source_build_apt_packages=(
    build-essential
    cmake
    meson
    ninja-build
    pkg-config
    flex
    bison
    check
    libpango1.0-dev
    libcairo2-dev
    libglib2.0-dev
    libgdk-pixbuf-2.0-dev
    libstartup-notification0-dev
    libxkbcommon-dev
    libxkbcommon-x11-dev
    libxcb1-dev
    libxcb-xkb-dev
    libxcb-randr0-dev
    libxcb-xinerama0-dev
    libxcb-util-dev
    libxcb-ewmh-dev
    libxcb-icccm4-dev
    libxcb-cursor-dev
    libxcb-keysyms1-dev
    libxcb-imdkit-dev
    libconfig-dev
    libdbus-1-dev
    libegl-dev
    libev-dev
    libgl-dev
    libepoxy-dev
    libpcre2-dev
    libpixman-1-dev
    libx11-xcb-dev
    libxcb-composite0-dev
    libxcb-damage0-dev
    libxcb-glx0-dev
    libxcb-image0-dev
    libxcb-present-dev
    libxcb-render0-dev
    libxcb-render-util0-dev
    libxcb-shape0-dev
    libxcb-sync-dev
    libxcb-xfixes0-dev
    uthash-dev
)

required_commands=(
    bspc
    sxhkd
    polybar
    rofi
    picom
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
    google-chrome-stable
    code
    cbonsai
    unimatrix
    asciiquarium
    anifetch
    fastfetch
)

usage() {
    cat <<EOF
Usage: ./install.sh [options]

Install this bspwm desktop setup and link the dotfiles into your home directory.

Options:
  --skip-packages   Do not install apt packages
  --skip-bashrc     Keep the existing ~/.bashrc instead of linking this one
  --link-bashrc     Link ~/.bashrc (the default; retained for compatibility)
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

run_as_root() {
    local sudo_cmd=()

    if (( EUID != 0 )); then
        if ! command -v sudo >/dev/null 2>&1 && (( ! dry_run )); then
            die "sudo is required to install packages"
        fi
        sudo_cmd=(sudo)
    fi

    run "${sudo_cmd[@]}" "$@"
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
            --skip-bashrc)
                link_bashrc=0
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
    local available=()
    local missing=()
    local package

    if ! command -v apt-get >/dev/null 2>&1; then
        warn "apt-get was not found; skipping package installation"
        warn "Install these packages manually: ${apt_packages[*]}"
        return 0
    fi

    log "Updating apt package lists"
    run_as_root apt-get update

    for package in "${apt_packages[@]}"; do
        if apt_package_available "$package"; then
            available+=("$package")
        else
            missing+=("$package")
        fi
    done

    if ((${#available[@]})); then
        log "Installing apt packages available for this Ubuntu release"
        run_as_root apt-get install -y "${available[@]}"
    fi

    if ((${#missing[@]})); then
        warn "packages not found in enabled apt repositories: ${missing[*]}"
        warn "continuing; missing commands will be reported after installation"
    fi
}

install_source_build_dependencies() {
    local available=()
    local missing=()
    local package

    if desktop_source_builds_current; then
        log "Pinned bspwm, Rofi, and Picom releases are already installed"
        return 0
    fi

    log "Checking dependencies for pinned desktop builds"
    for package in "${source_build_apt_packages[@]}"; do
        if apt_package_available "$package"; then
            available+=("$package")
        else
            missing+=("$package")
        fi
    done

    if ((${#missing[@]})); then
        warn "source-build packages not found: ${missing[*]}"
        return 1
    fi

    if ((${#available[@]})); then
        run_as_root apt-get install -y "${available[@]}"
    fi
}

apt_package_available() {
    local candidate

    candidate="$(
        LC_ALL=C apt-cache policy "$1" 2>/dev/null |
            awk '$1 == "Candidate:" { print $2; exit }'
    )"

    [[ -n "$candidate" && "$candidate" != "(none)" ]]
}

fastfetch_release_arch() {
    local arch

    arch="$(dpkg --print-architecture)"
    case "$arch" in
        amd64)
            printf 'amd64'
            ;;
        arm64)
            printf 'aarch64'
            ;;
        armhf)
            printf 'armv7l'
            ;;
        armel)
            printf 'armv6l'
            ;;
        i386)
            printf 'i686'
            ;;
        ppc64el)
            printf 'ppc64le'
            ;;
        riscv64|s390x)
            printf '%s' "$arch"
            ;;
        *)
            return 1
            ;;
    esac
}

download_file() {
    local url="$1"
    local output="$2"

    if command -v curl >/dev/null 2>&1 || (( dry_run )); then
        run curl -fsSL -o "$output" "$url"
    elif command -v wget >/dev/null 2>&1; then
        run wget -qO "$output" "$url"
    else
        warn "curl or wget is required to download $url"
        return 1
    fi
}

install_google_chrome() {
    local arch
    local deb_path
    local deb_url

    if command -v google-chrome-stable >/dev/null 2>&1; then
        log "Google Chrome is already installed"
        return 0
    fi

    arch="$(dpkg --print-architecture)"
    case "$arch" in
        amd64|arm64)
            ;;
        *)
            warn "Google Chrome's Debian package is unavailable for architecture: $arch"
            return 1
            ;;
    esac

    deb_path="${TMPDIR:-/tmp}/google-chrome-stable-current-${arch}.deb"
    deb_url="https://dl.google.com/linux/direct/google-chrome-stable_current_${arch}.deb"

    log "Downloading Google Chrome"
    download_file "$deb_url" "$deb_path"
    log "Installing Google Chrome"
    run_as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y "$deb_path"

    if (( ! dry_run )); then
        rm -f -- "$deb_path"
    fi
}

install_vscode() {
    local arch
    local platform
    local deb_path
    local deb_url

    if command -v code >/dev/null 2>&1; then
        log "Visual Studio Code is already installed"
        return 0
    fi

    arch="$(dpkg --print-architecture)"
    case "$arch" in
        amd64)
            platform='linux-deb-x64'
            ;;
        arm64)
            platform='linux-deb-arm64'
            ;;
        armhf)
            platform='linux-deb-armhf'
            ;;
        *)
            warn "Visual Studio Code's Debian package is unavailable for architecture: $arch"
            return 1
            ;;
    esac

    deb_path="${TMPDIR:-/tmp}/visual-studio-code-current-${arch}.deb"
    deb_url="https://update.code.visualstudio.com/latest/${platform}/stable"

    if command -v debconf-set-selections >/dev/null 2>&1; then
        printf '%s\n' 'code code/add-microsoft-repo boolean true' |
            run_as_root debconf-set-selections
    fi

    log "Downloading Visual Studio Code"
    download_file "$deb_url" "$deb_path"
    log "Installing Visual Studio Code"
    run_as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y "$deb_path"

    if (( ! dry_run )); then
        rm -f -- "$deb_path"
    fi
}

install_vscode_extensions() {
    local extension='openai.chatgpt'

    if ! command -v code >/dev/null 2>&1 && (( ! dry_run )); then
        warn "Visual Studio Code is required to install the $extension extension"
        return 1
    fi

    if command -v code >/dev/null 2>&1 &&
        code --list-extensions 2>/dev/null | grep -Fqx "$extension"; then
        log "VS Code extension $extension is already installed"
        return 0
    fi

    log "Installing VS Code extension: $extension"
    run code --install-extension "$extension"
}

install_snap_animation() {
    local command_name="$1"
    local snap_name="$2"

    if command -v "$command_name" >/dev/null 2>&1; then
        log "$command_name is already installed"
        return 0
    fi

    if ! command -v snap >/dev/null 2>&1 && (( ! dry_run )); then
        warn "snap is required to install $command_name"
        return 1
    fi

    log "Installing $command_name from the Snap Store"
    run_as_root snap install "$snap_name"
}

install_unimatrix() {
    local package_url='git+https://github.com/will8211/unimatrix.git'

    if command -v unimatrix >/dev/null 2>&1; then
        log "unimatrix is already installed"
        return 0
    fi

    if ! command -v pipx >/dev/null 2>&1 && (( ! dry_run )); then
        warn "pipx is required to install unimatrix"
        return 1
    fi

    log "Installing unimatrix with pipx"
    run pipx install "$package_url"
}

bspwm_release_is_current() {
    command -v bspwm >/dev/null 2>&1 &&
        [[ "$(bspwm -v 2>/dev/null)" == "$bspwm_version" ]]
}

rofi_release_is_current() {
    command -v rofi >/dev/null 2>&1 &&
        rofi -version 2>/dev/null | head -n1 | grep -Fq "$rofi_version"
}

picom_release_is_current() {
    command -v picom >/dev/null 2>&1 &&
        picom --version 2>/dev/null | head -n1 | grep -Fq "$picom_version"
}

desktop_source_builds_current() {
    bspwm_release_is_current && rofi_release_is_current && picom_release_is_current
}

new_build_root() {
    local name="$1"

    if (( dry_run )); then
        printf '%s/dotfiles-%s-build.dry-run' "${TMPDIR:-/tmp}" "$name"
    else
        mktemp -d "${TMPDIR:-/tmp}/dotfiles-${name}-build.XXXXXX"
    fi
}

clean_build_root() {
    local build_root="$1"

    if (( dry_run )); then
        return 0
    fi

    case "$build_root" in
        "${TMPDIR:-/tmp}"/dotfiles-*-build.*)
            rm -rf -- "$build_root"
            ;;
        *)
            warn "refusing to remove unexpected build directory: $build_root"
            return 1
            ;;
    esac
}

install_bspwm_release() {
    local build_root
    local source_dir

    if bspwm_release_is_current; then
        log "bspwm $bspwm_version is already installed"
        return 0
    fi

    build_root="$(new_build_root bspwm)"
    source_dir="$build_root/source"
    log "Building bspwm $bspwm_version"
    run git clone --quiet --depth 1 --branch "$bspwm_version" \
        https://github.com/baskerville/bspwm.git "$source_dir"
    run make -C "$source_dir"
    run_as_root make -C "$source_dir" install
    clean_build_root "$build_root"
}

install_rofi_release() {
    local build_root
    local source_dir

    if rofi_release_is_current; then
        log "Rofi $rofi_version is already installed"
        return 0
    fi

    build_root="$(new_build_root rofi)"
    source_dir="$build_root/source"
    log "Building Rofi $rofi_version"
    run git clone --quiet --recursive --depth 1 --branch "$rofi_version" \
        https://github.com/davatorium/rofi.git "$source_dir"
    run meson setup "$source_dir/build" "$source_dir" \
        --buildtype=release -Dxcb=enabled -Dwayland=disabled
    run ninja -C "$source_dir/build"
    run_as_root ninja -C "$source_dir/build" install
    clean_build_root "$build_root"
}

install_picom_release() {
    local build_root
    local source_dir

    if picom_release_is_current; then
        log "Picom $picom_version is already installed"
        return 0
    fi

    build_root="$(new_build_root picom)"
    source_dir="$build_root/source"
    log "Building Picom $picom_version"
    run git clone --quiet --depth 1 --branch "$picom_version" \
        https://github.com/yshui/picom.git "$source_dir"
    run meson setup "$source_dir/build" "$source_dir" --buildtype=release
    run ninja -C "$source_dir/build"
    run_as_root ninja -C "$source_dir/build" install
    clean_build_root "$build_root"
}

install_desktop_releases() {
    install_bspwm_release
    install_rofi_release
    install_picom_release
}

install_fastfetch() {
    local release_arch
    local deb_path
    local deb_url

    if command -v fastfetch >/dev/null 2>&1; then
        log "fastfetch is already installed"
        return 0
    fi

    if apt_package_available fastfetch; then
        log "Installing fastfetch from apt"
        run_as_root apt-get install -y fastfetch
        return $?
    fi

    if ! release_arch="$(fastfetch_release_arch)"; then
        warn "unsupported architecture for fastfetch GitHub release: $(dpkg --print-architecture)"
        return 0
    fi

    deb_path="${TMPDIR:-/tmp}/fastfetch-linux-${release_arch}.deb"
    deb_url="https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-${release_arch}.deb"

    log "Downloading fastfetch Debian package"
    if ! download_file "$deb_url" "$deb_path"; then
        return 1
    fi

    log "Installing fastfetch Debian package"
    run_as_root apt-get install -y "$deb_path"
}

install_anifetch() {
    local package_url='git+https://github.com/Notenlish/anifetch.git#egg=anifetch-cli'

    if command -v anifetch >/dev/null 2>&1; then
        log "anifetch is already installed"
        return 0
    fi

    if ! command -v pipx >/dev/null 2>&1 && (( ! dry_run )); then
        warn "pipx is required to install anifetch"
        return 1
    fi

    log "Installing anifetch with pipx"
    if ! run pipx install "$package_url"; then
        return 1
    fi

    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        warn "pipx installs commands to ~/.local/bin, which is not currently in PATH"
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

link_fonts() {
    local legacy_target="$HOME/.local/share/fonts"

    # Older versions of this setup linked the whole fonts directory. Avoid
    # creating a self-referential link inside it when that layout is present.
    if [[ -L "$legacy_target" ]] &&
        [[ "$(readlink -- "$legacy_target")" == "$dotfiles_dir/fonts" ]]; then
        log "Already linked: $legacy_target"
        return 0
    fi

    link_item "$dotfiles_dir/fonts" "$legacy_target/dotfiles-fonts"
}

link_dotfiles() {
    log "Creating config and asset symlinks"

    link_item "$dotfiles_dir/bspwm" "$HOME/.config/bspwm"
    link_item "$dotfiles_dir/picom" "$HOME/.config/picom"
    link_item "$dotfiles_dir/polybar" "$HOME/.config/polybar"
    link_item "$dotfiles_dir/rofi" "$HOME/.config/rofi"
    link_item "$dotfiles_dir/sxhkd" "$HOME/.config/sxhkd"
    link_item "$dotfiles_dir/anifetch" "$HOME/.config/anifetch"
    link_item "$dotfiles_dir/fastfetch" "$HOME/.config/fastfetch"
    link_item "$dotfiles_dir/colors.txt" "$HOME/.config/colors.txt"
    link_item "$dotfiles_dir/xfce4/terminal/accels.scm" "$HOME/.config/xfce4/terminal/accels.scm"
    link_item "$dotfiles_dir/xfce4/helpers.rc" "$HOME/.config/xfce4/helpers.rc"
    link_item "$dotfiles_dir/autostart/anifetch-terminal.desktop" "$HOME/.config/autostart/anifetch terminal.desktop"
    link_item "$dotfiles_dir/vscode/settings.json" "$HOME/.config/Code/User/settings.json"

    link_item "$dotfiles_dir/wallpapers" "$HOME/Pictures/wallpapers"
    link_item "$dotfiles_dir/rofi_images" "$HOME/Pictures/rofi_images"
    link_fonts
    link_item "$dotfiles_dir/.bash_aliases" "$HOME/.bash_aliases"

    if (( link_bashrc )); then
        link_item "$dotfiles_dir/.bashrc" "$HOME/.bashrc"
    else
        log "Skipping ~/.bashrc as requested"
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
    run chmod +x "$dotfiles_dir/xfce4/apply-settings.sh"
}

apply_desktop_settings() {
    log "Applying XFCE Terminal, appearance, theme, and power settings"
    if ! run "$dotfiles_dir/xfce4/apply-settings.sh"; then
        warn "some desktop settings could not be applied in this session"
    fi
}

refresh_generated_files() {
    if command -v fc-cache >/dev/null 2>&1 || (( dry_run )); then
        log "Refreshing font cache"
        run fc-cache -f "$HOME/.local/share/fonts"
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

    if ! command -v feh >/dev/null 2>&1 &&
        ! command -v nitrogen >/dev/null 2>&1; then
        warn "no supported wallpaper setter found; install feh or nitrogen"
    fi

    if ! command -v fastfetch >/dev/null 2>&1 ||
        ! command -v anifetch >/dev/null 2>&1 ||
        ! command -v chafa >/dev/null 2>&1 ||
        ! command -v ffmpeg >/dev/null 2>&1; then
        warn "the optional myfetch command needs fastfetch, anifetch, chafa, and ffmpeg"
    fi

    if ! bspwm_release_is_current; then
        warn "bspwm $bspwm_version is required to match this machine (found: $(bspwm -v 2>/dev/null || printf missing))"
    fi

    if ! rofi_release_is_current; then
        warn "Rofi $rofi_version is required to match this machine"
    fi

    if ! picom_release_is_current; then
        warn "Picom $picom_version is required for the configured animation rules"
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
        install_source_build_dependencies
        install_desktop_releases
        install_google_chrome
        install_vscode
        install_vscode_extensions
        install_snap_animation cbonsai cbonsai
        install_snap_animation asciiquarium asciiquarium
        install_unimatrix
        if ! install_fastfetch; then
            warn "fastfetch installation failed; continuing without the optional myfetch integration"
        fi
        if ! install_anifetch; then
            warn "anifetch installation failed; continuing without the optional myfetch integration"
        fi
    else
        log "Skipping package installation"
    fi

    prepare_scripts
    link_dotfiles
    apply_desktop_settings
    refresh_generated_files
    check_commands

    log "Install complete"
    if (( backup_created )); then
        printf 'Backups were saved in: %s\n' "$backup_dir"
    fi
    printf 'Start or restart your bspwm session to use the setup.\n'
}

main "$@"
