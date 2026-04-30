# Dotfiles

My Xubuntu `bspwm` desktop setup built with `polybar`, `rofi`, `picom`, and `sxhkd`.

The theme is shared across the desktop through a palette file in `colors.txt`. A helper script, `gradient.py`, turns that palette into matching color files for Polybar and Rofi, so the bar, launcher, and powermenu stay in sync.

## What this repo includes

- `bspwm` window manager config
- `sxhkd` keybindings
- `polybar` with workspace, launcher, system, network, and clock modules
- `rofi` app launcher, powermenu, and Alt+Tab switcher
- `picom` config with blur, rounded corners, opacity rules, and animations
- rotating wallpaper and random launcher-image helpers
- bundled fonts, wallpapers, and image assets
- a small `.bashrc` tweak

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

## Features

- Five `bspwm` desktops, `I` through `V`
- Shared palette generation for Polybar and Rofi via `bspwm/scripts/gradient.py`
- Polybar launcher buttons for browser, terminal, file manager, and VS Code
- Rofi app launcher with a randomly selected side image
- Rofi powermenu applet
- Thumbnail-based Alt+Tab menu
- `picom` animations
- Wallpaper rotation via `nitrogen`

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
- `pavucontrol`
- `network-manager` tools such as `nm-connection-editor`
- one lock command such as `betterlockscreen`, `i3lock-color`, `i3lock`, `slock`, or `xscreensaver-command`
- Nerd Fonts, especially `JetBrainsMono Nerd Font` and `Symbols Nerd Font Mono`

The current Rofi configs also reference the `Colloid` and `elementary-xfce` icon themes.

## Installation

This repo is laid out to mirror `~/.config`, so symlinking works well.

```bash
mkdir -p ~/.config ~/.local/share/fonts ~/Pictures

ln -sfn "$PWD/bspwm" ~/.config/bspwm
ln -sfn "$PWD/picom" ~/.config/picom
ln -sfn "$PWD/polybar" ~/.config/polybar
ln -sfn "$PWD/rofi" ~/.config/rofi
ln -sfn "$PWD/sxhkd" ~/.config/sxhkd
ln -sfn "$PWD/colors.txt" ~/.config/colors.txt

ln -sfn "$PWD/wallpapers" ~/Pictures/wallpapers
ln -sfn "$PWD/rofi_images" ~/Pictures/rofi_images
ln -sfn "$PWD/fonts" ~/.local/share/fonts/dotfiles-fonts

fc-cache -fv
```

After that:

1. Start `bspwm` from your display manager or session.
2. Let `bspwmrc` launch `sxhkd`, `picom`, `polybar`, the palette generator, and the wallpaper loop.
3. Adjust the machine-specific values listed below before treating this as plug-and-play.

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

Whenever you change `colors.txt`, regenerate the shared colors with:

```bash
python3 ~/.config/bspwm/scripts/gradient.py
```

## Machine-specific notes

This setup is personal enough that a few values should be updated on a new machine:

- `polybar/config.ini` uses `wlp0s20f3` for Wi-Fi and `enp0s3` for Ethernet
- the bar launches `google-chrome-stable`, `xfce4-terminal`, `thunar`, and `code`
- `rofi/config.rasi` uses the `Colloid` icon theme
- `rofi/powermenu.rasi` uses the `elementary-xfce` icon theme
- `bspwm/scripts/wallpaper.sh` expects wallpapers in `~/Pictures/wallpapers`
- `bspwm/scripts/rofi_launcher.sh` expects launcher images in `~/Pictures/rofi_images`

## Included assets

- `fonts/` contains JetBrains Mono Nerd Font and Symbols Nerd Font files
- `wallpapers/` contains the wallpaper pool used by the rotator
- `rofi_images/` contains the images used by the launcher
