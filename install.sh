#!/bin/bash
set -e

# USB Keyboard Layout Auto-Configuration - Installer

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="/usr/local/bin"
UDEV_DIR="/etc/udev/rules.d"
SYSTEM_CONFIG_DIR="/etc/kbd-auto-layout"
USER_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/kbd-auto-layout"
LOG_FILE="/var/log/kbd-auto-layout.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

check_root() {
    if [ "$EUID" -ne 0 ]; then
        error "This script must be run as root (use sudo)"
        exit 1
    fi
}

install_scripts() {
    info "Installing scripts to $INSTALL_DIR..."

    install -m 755 "$SCRIPT_DIR/kbd-auto-layout" "$INSTALL_DIR/"
    install -m 755 "$SCRIPT_DIR/kbd-auto-layout-udev" "$INSTALL_DIR/"

    if [ -f "$SCRIPT_DIR/kbd-auto-layout-gui" ]; then
        install -m 755 "$SCRIPT_DIR/kbd-auto-layout-gui" "$INSTALL_DIR/"
    fi
}

install_udev_rules() {
    info "Installing udev rules to $UDEV_DIR..."

    install -m 644 "$SCRIPT_DIR/udev/99-kbd-auto-layout.rules" "$UDEV_DIR/"
}

install_config() {
    info "Installing default config to $SYSTEM_CONFIG_DIR..."

    mkdir -p "$SYSTEM_CONFIG_DIR"

    if [ ! -f "$SYSTEM_CONFIG_DIR/keyboards.yaml" ]; then
        install -m 644 "$SCRIPT_DIR/config/keyboards.yaml" "$SYSTEM_CONFIG_DIR/"
    else
        warn "Config already exists, skipping (backup at keyboards.yaml.new)"
        install -m 644 "$SCRIPT_DIR/config/keyboards.yaml" "$SYSTEM_CONFIG_DIR/keyboards.yaml.new"
    fi
}

setup_user_config() {
    local real_user="${SUDO_USER:-$USER}"
    local real_home
    real_home=$(getent passwd "$real_user" | cut -d: -f6)
    local user_config_dir="$real_home/.config/kbd-auto-layout"

    info "Setting up user config directory for $real_user..."

    sudo -u "$real_user" mkdir -p "$user_config_dir"

    if [ ! -f "$user_config_dir/keyboards.yaml" ]; then
        sudo -u "$real_user" cp "$SCRIPT_DIR/config/keyboards.yaml" "$user_config_dir/"
        info "User config created at $user_config_dir/keyboards.yaml"
    else
        warn "User config already exists at $user_config_dir/keyboards.yaml"
    fi
}

install_autostart() {
    local real_user="${SUDO_USER:-$USER}"
    local real_home
    real_home=$(getent passwd "$real_user" | cut -d: -f6)
    local autostart_dir="$real_home/.config/autostart"

    info "Installing autostart entry for $real_user..."

    sudo -u "$real_user" mkdir -p "$autostart_dir"
    install -m 644 -o "$real_user" "$SCRIPT_DIR/autostart/kbd-auto-layout.desktop" "$autostart_dir/"
}

setup_log() {
    info "Setting up log file..."

    touch "$LOG_FILE"
    chmod 666 "$LOG_FILE"
}

reload_udev() {
    info "Reloading udev rules..."

    udevadm control --reload-rules
    udevadm trigger
}

show_summary() {
    echo ""
    info "Installation complete!"
    echo ""
    echo "Files installed:"
    echo "  - $INSTALL_DIR/kbd-auto-layout"
    echo "  - $INSTALL_DIR/kbd-auto-layout-udev"
    [ -f "$INSTALL_DIR/kbd-auto-layout-gui" ] && echo "  - $INSTALL_DIR/kbd-auto-layout-gui"
    echo "  - $UDEV_DIR/99-kbd-auto-layout.rules"
    echo "  - $SYSTEM_CONFIG_DIR/keyboards.yaml"
    echo "  - ~/.config/autostart/kbd-auto-layout.desktop"
    echo ""
    echo "User config: ~/.config/kbd-auto-layout/keyboards.yaml"
    echo "Log file: $LOG_FILE"
    echo ""
    echo "Usage:"
    echo "  kbd-auto-layout          # Launch configurator (if gui installed)"
    echo "  kbd-auto-layout list     # List detected keyboards"
    echo "  kbd-auto-layout reload   # Apply layouts now"
    echo ""
    warn "For i3wm, add to ~/.config/i3/config:"
    echo "  exec --no-startup-id kbd-auto-layout reload"
    echo ""
}

main() {
    echo "USB Keyboard Layout Auto-Configuration - Installer"
    echo "=================================================="
    echo ""

    check_root

    install_scripts
    install_udev_rules
    install_config
    setup_user_config
    install_autostart
    setup_log
    reload_udev

    show_summary
}

main "$@"
