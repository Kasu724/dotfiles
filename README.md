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
- `nitrogen` rotating wallpaper and random launcher-image helpers
- `.bashrc` tweak for different terminal colors

## Layout

```text
├── .bashrc
├── bspwm/
├── colors.txt
├── fonts/
├── icons/
├── picom/
├── polybar/
├── rofi/
├── rofi_images/
├── sxhkd/
└── wallpapers/
```

## Dependencies

Package names vary by distro, but this setup expects roughly:

- `bspwm`
- `sxhkd`
- `polybar`
- `rofi`
- `picom`
- `nitrogen`
- `python3`
- `xfsettingsd`
- `xfce4-terminal`
- `flameshot`
- `pavucontrol`
- `network-manager` tools such as `nm-connection-editor`
- one lock command such as `betterlockscreen`, `i3lock-color`, `i3lock`, `slock`, or `xscreensaver-command`
- Nerd Fonts, especially `JetBrainsMono Nerd Font` and `Symbols Nerd Font Mono`

## Installation

This repo is laid out to mirror `~/.config`, so symlinking works well.

```bash
./install.sh
```

The installer:

- installs the Xubuntu/apt packages needed by the configs and scripts
- creates the `~/.config`, `~/Pictures`, and font symlinks
- backs up existing files or directories before replacing them with symlinks
- refreshes the font cache
- regenerates the Polybar and Rofi color files

It does not replace `~/.bashrc` by default. To link the bundled shell config too, run:

```bash
./install.sh --link-bashrc
```

Useful options:

```bash
./install.sh --skip-packages
./install.sh --dry-run
```

After installation:

1. Start `bspwm` from your display manager or session.
2. Let `bspwmrc` launch `sxhkd`, `picom`, `polybar`, the palette generator, and the wallpaper loop.
3. Adjust the machine-specific values listed below before treating this as plug-and-play.

To make anifetch run on startup:
1. Settings → Session and Startup → Application Autostart
2. Click Add
3. Command: `xfce4-terminal -e "myfetch; bash"`
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
- `polybar/config.ini`: launcher apps, fonts, modules, and network interface names
- `rofi/config.rasi`, `rofi/powermenu.rasi`, `rofi/alt-tab.rasi`: launcher and switcher styling
- `picom/picom.conf`: blur, opacity, shadows, corner radius, and animation behavior
- `.bash_alises`: command aliases

## Machine-specific notes

A few values should be updated on a new machine:

- `polybar/config.ini` uses `wlp0s20f3` for Wi-Fi and `enp0s3` for Ethernet
- `polybar` launches `google-chrome-stable`, `xfce4-terminal`, `thunar`, and `code`
- `bspwm/scripts/wallpaper.sh` expects wallpapers in `~/Pictures/wallpapers`
- `bspwm/scripts/rofi_launcher.sh` expects launcher images in `~/Pictures/rofi_images`

## Included assets

- `fonts/` contains JetBrains Mono Nerd Font and Symbols Nerd Font files
- `wallpapers/` contains the wallpaper pool used by the rotator
- `rofi_images/` contains the images used by the launcher
- Aliases:
    - `mybonsai`: custom cbonsai animation
    - `myfetch`: custom anifetch animation