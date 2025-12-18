#!/bin/bash
set -e

# USB Keyboard Layout Auto-Configuration - Uninstaller

INSTALL_DIR="/usr/local/bin"
UDEV_DIR="/etc/udev/rules.d"
SYSTEM_CONFIG_DIR="/etc/kbd-auto-layout"
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

remove_scripts() {
    info "Removing scripts from $INSTALL_DIR..."

    rm -f "$INSTALL_DIR/kbd-auto-layout"
    rm -f "$INSTALL_DIR/kbd-auto-layout-udev"
    rm -f "$INSTALL_DIR/kbd-auto-layout-gui"
}

remove_udev_rules() {
    info "Removing udev rules..."

    rm -f "$UDEV_DIR/99-kbd-auto-layout.rules"
}

remove_system_config() {
    info "Removing system config..."

    rm -rf "$SYSTEM_CONFIG_DIR"
}

remove_log() {
    info "Removing log file..."

    rm -f "$LOG_FILE"
}

reload_udev() {
    info "Reloading udev rules..."

    udevadm control --reload-rules
}

main() {
    echo "USB Keyboard Layout Auto-Configuration - Uninstaller"
    echo "====================================================="
    echo ""

    check_root

    remove_scripts
    remove_udev_rules
    remove_system_config
    remove_log
    reload_udev

    echo ""
    info "Uninstallation complete!"
    echo ""
    warn "User configs in ~/.config/kbd-auto-layout/ were NOT removed."
    echo "Remove them manually if needed."
    echo ""
}

main "$@"
