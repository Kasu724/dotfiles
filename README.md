# Dotfiles

My Xubuntu `bspwm` desktop setup with `polybar`, `rofi`, `picom`, and `sxhkd`.

The color theme is shared across the desktop through a palette file in `colors.txt`.  A helper script, `gradient.py`, turns that palette into matching color files for Polybar and Rofi.

I like Ninomae Ina'nis

## Features

- `bspwm` window manager config
- `sxhkd` keybindings
- `polybar` with workspace, launcher, system, network, and clock modules
- `rofi` app launcher, powermenu, and Alt+Tab switcher
- `picom` config with blur, rounded corners, opacity rules, and animations
- `feh` rotating wallpaper (with `nitrogen` as a fallback) and random launcher-image helpers
- XFCE Terminal palette, font, cursor, keyboard shortcuts, and 30% transparency
- purple `user@host`, orange path, and white separator/prompt shell colors
- Adwaita Dark GTK theme with Adwaita icons and cursor, including GTK 4 dark preference
- reproducible application installation and anifetch terminal autostart

## Layout

```text
├── .bash_aliases
├── .bashrc
├── anifetch/
├── autostart/
├── bspwm/
├── colors.txt
├── fastfetch/
├── fonts/
├── picom/
├── polybar/
├── rofi/
├── rofi_images/
├── sxhkd/
├── wallpapers/
├── vscode/
├── xfce4/
├── install.sh
└── update.sh
```

## Dependencies

The installer targets Ubuntu/Xubuntu and installs the complete runtime set,
including:

- `bspwm` 0.9.12
- `sxhkd`
- `polybar`
- `rofi` 2.0.0
- `picom` v13 (needed by the animation rules)
- `feh` and `nitrogen`
- `python3`
- XFCE settings/session tools and `xfce4-terminal`
- Google Chrome and Visual Studio Code
- `flameshot`
- shell completion, desktop notifications, and the standard command-line helpers used by the scripts
- `pavucontrol`
- `network-manager` tools such as `nm-connection-editor`
- `cbonsai`, `unimatrix`, `asciiquarium`, `anifetch`, `fastfetch`, `chafa`, and `ffmpeg`
- Adwaita themes/icons, Noto UI fonts, and the included Nerd Fonts
- one lock command such as `betterlockscreen`, `i3lock-color`, `i3lock`, `slock`, or `xscreensaver-command`

Ubuntu 24.04's bspwm, Rofi, and Picom packages are older than the binaries on
the source machine. The installer therefore builds the pinned upstream releases
when those exact versions are not already available. Chrome and VS Code are
installed from their official Debian packages; the terminal animations use
Snap or isolated `pipx` environments.

## Installation

This repo is laid out to mirror `~/.config`, so symlinking works well.

```bash
./install.sh
```

The installer:

- installs the Xubuntu/apt packages needed by the configs and scripts
- installs Chrome, VS Code, and every command used by the aliases
- installs the tracked VS Code extension and links its portable editor settings
- builds the pinned bspwm, Rofi, and Picom releases when necessary
- creates the `~/.config`, `~/Pictures`, and font symlinks
- links the shell, terminal-shortcut, default-browser, autostart, and application configs
- applies the XFCE Terminal palette/transparency and GTK dark appearance
- backs up existing files or directories before replacing them with symlinks
- refreshes the font cache
- regenerates the Polybar and Rofi color files

The bundled `.bashrc` is linked by default so the prompt colors are reproduced.
To preserve an existing `.bashrc`, use:

```bash
./install.sh --skip-bashrc
```

Useful options:

```bash
./install.sh --skip-packages
./install.sh --dry-run
```

## Updating another machine

After committing and pushing changes from one machine, update an already
installed machine with:

```bash
./update.sh
```

The updater pulls the current branch with `--ff-only`, reruns the installer
without installing packages, and refreshes the generated color and font files.
It keeps local changes and stops if they conflict with the incoming commits.

After dependency changes, or when bringing a partially configured machine up
to date, include package installation:

```bash
./update.sh --packages
```

To also reload a running bspwm desktop and its components:

```bash
./update.sh --reload
```

After installation:

1. Start `bspwm` from your display manager or session.
2. Let `bspwmrc` launch `sxhkd`, `picom`, `polybar`, the palette generator, and the wallpaper loop.
3. The tracked XFCE autostart entry opens `myfetch` in a terminal.

## Keybindings

The main bindings live in `sxhkd/sxhkdrc`.

- `Super + Return`: open `xfce4-terminal`
- `Super + d` or `Ctrl + Space`: open the Rofi launcher
- `Super + Shift + d` or `Ctrl + Shift + Space`: open the powermenu
- `Alt + Tab`: open the Rofi window switcher
- `Super + q`: close the focused window
- `Super + Arrow`: focus a window in that direction
- `Super + Shift + Arrow`: move a window in that direction
- `Super + z`: toggle floating
- `Super + a`: toggle the desktop layout state
- `Super + h`: hide the focused window
- `Super + j`: restore the most recently hidden window

## Customization

Start here if you want to make the setup your own:

- `colors.txt`: source palette for Polybar and Rofi
- `bspwm/scripts/gradient.py`: generates `polybar/colors.ini` and `rofi/colors.rasi`
- `bspwm/scripts/wallpaper.sh`: changes the wallpaper every 10 minutes
- `bspwm/scripts/rofi_launcher.sh`: selects a random image for the launcher panel
- `polybar/config.ini`: launcher apps, fonts, and modules
- `rofi/config.rasi`, `rofi/powermenu.rasi`, `rofi/alt-tab.rasi`: launcher and switcher styling
- `picom/picom.conf`: blur, opacity, shadows, corner radius, and animation behavior
- `xfce4/apply-settings.sh`: terminal colors/transparency, DPI, GTK theme, icons, and dark mode
- `xfce4/terminal/accels.scm`: terminal tab shortcuts
- `vscode/settings.json`: editor font, layout, autosave, Git, and dark-theme behavior
- `.bash_aliases`: command aliases

## Machine-specific notes

Portable visual and behavioral settings are tracked. These categories are
deliberately not copied because they are hardware-specific or sensitive:

- monitor geometry and output names
- keyboard and pointer device IDs
- Wi-Fi credentials, browser profiles, histories, caches, tokens, and keyrings

The wallpaper and launcher-image directories are symlinked into `~/Pictures`,
so their paths remain portable between machines.

## Included assets

- `fonts/` contains JetBrains Mono Nerd Font and Symbols Nerd Font files
- `wallpapers/` contains the wallpaper pool used by the rotator
- `rofi_images/` contains the images used by the launcher
- Aliases:
    - `mybonsai`: custom cbonsai animation
    - `mymatrix`: custom unimatrix animation
    - `myquarium`: custom asciiquarium animation
    - `myfetch`: custom anifetch animation
