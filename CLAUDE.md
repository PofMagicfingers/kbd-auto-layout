# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

USB keyboard layout auto-configuration scripts for Linux (X11). Automatically applies specific keyboard layouts when USB keyboards are plugged in, and re-applies them after DKMS module rebuilds.

## Architecture

```
kbd-auto-layout/
├── kbd-auto-layout          # Main script - layout detection & application
├── kbd-auto-layout-udev     # Wrapper called by udev, handles logging
├── kbd-auto-layout-gui      # Interactive configurator (requires gum)
├── autostart/
│   └── kbd-auto-layout.desktop  # XDG autostart entry (GNOME/KDE/XFCE)
├── config/
│   └── keyboards.yaml    # Default keyboard configuration
├── udev/
│   └── 99-kbd-auto-layout.rules  # udev rules for keyboard & module events
├── install.sh            # Installation script (requires root)
└── uninstall.sh          # Uninstallation script (requires root)
```

## Configuration

YAML config file searched in order:
1. `~/.config/kbd-auto-layout/keyboards.yaml` (user)
2. `/etc/kbd-auto-layout/keyboards.yaml` (system)

Config format:
```yaml
keyboards:
  - name: "8BitDo"
    layout: us
    variant: intl
    model: pc105
```

## Usage

```bash
kbd-auto-layout              # Launch interactive configurator (if gui installed)
kbd-auto-layout reload       # Re-apply layouts (like a fresh plug-in)
kbd-auto-layout list         # List detected keyboards
kbd-auto-layout in           # Apply layouts (called by udev)
kbd-auto-layout out          # Restore settings (called by udev)
```

## udev Triggers

The script is triggered by udev on:
- USB keyboard plug/unplug (`SUBSYSTEM=="input"`)
- HID module reload after DKMS rebuild (`SUBSYSTEM=="module"`, `KERNEL=="usbhid|hid_generic"`)

## Dependencies

Required:
- `setxkbmap`, `xinput` (X11 tools)

Optional:
- `yq` - for proper YAML parsing (falls back to awk)
- `gum` - for interactive TUI configurator
- `gsettings` - for GNOME integration
- `notify-send` - for desktop notifications

## Installation

```bash
sudo ./install.sh
```

This installs:
- Scripts to `/usr/local/bin/`
- udev rules to `/etc/udev/rules.d/`
- System config to `/etc/kbd-auto-layout/`
- User config to `~/.config/kbd-auto-layout/`
- Autostart entry to `~/.config/autostart/` (for GNOME/KDE/XFCE)

## Autostart at Boot

The XDG autostart entry works with GNOME, KDE, and XFCE.

For **i3wm**, add to `~/.config/i3/config`:
```
exec --no-startup-id kbd-auto-layout reload
```
