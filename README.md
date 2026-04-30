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

This repo is laid out to mirror `~/.config`, so symlinking is intended

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
