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
    local desktop_file="$autostart_dir/kbd-auto-layout.desktop"
    local source_file="$SCRIPT_DIR/autostart/kbd-auto-layout.desktop"

    # Already installed?
    if [ -f "$desktop_file" ]; then
        if diff -q "$source_file" "$desktop_file" > /dev/null 2>&1; then
            info "XDG autostart already installed"
            return 0
        fi
    fi

    info "Installing XDG autostart entry for $real_user..."

    sudo -u "$real_user" mkdir -p "$autostart_dir"

    # Show diff
    echo ""
    echo "Proposed file: $desktop_file"
    echo ""
    if [ -f "$desktop_file" ]; then
        if command -v git &> /dev/null; then
            git diff --no-index "$desktop_file" "$source_file" || true
        else
            diff -u --color=always "$desktop_file" "$source_file" || true
        fi
    else
        echo -e "\033[32m$(cat "$source_file")\033[0m"
    fi
    echo ""

    # Ask for confirmation
    read -p "Install this autostart entry? [y/N] " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        install -m 644 -o "$real_user" "$source_file" "$desktop_file"
        info "XDG autostart installed"
    else
        warn "Skipped XDG autostart"
    fi
}

setup_i3_autostart() {
    local real_user="${SUDO_USER:-$USER}"
    local real_home
    real_home=$(getent passwd "$real_user" | cut -d: -f6)

    # Find i3 config file
    local i3_config=""
    if [ -f "$real_home/.config/i3/config" ]; then
        i3_config="$real_home/.config/i3/config"
    elif [ -f "$real_home/.i3/config" ]; then
        i3_config="$real_home/.i3/config"
    else
        return 0
    fi

    # Already configured?
    if grep -q "kbd-auto-layout" "$i3_config"; then
        info "i3 autostart already configured"
        return 0
    fi

    info "Found i3 config at $i3_config"

    # Block to insert
    local insert_block
    read -r -d '' insert_block <<'EOF' || true

# Autostart kbd-auto-layout
exec_always --no-startup-id kbd-auto-layout reload
EOF

    # Create modified version
    local tmp_file
    tmp_file=$(mktemp)

    if grep -vE "^\s*#" "$i3_config" | grep -qE "exec_always --no-startup-id"; then
        # Insert before first non-commented exec_always --no-startup-id
        local first_line
        first_line=$(grep -nE "exec_always --no-startup-id" "$i3_config" | grep -vE "^[0-9]+:\s*#" | head -1 | cut -d: -f1)
        head -n "$((first_line - 1))" "$i3_config" > "$tmp_file"
        echo "$insert_block" >> "$tmp_file"
        echo "" >> "$tmp_file"
        tail -n +"$first_line" "$i3_config" >> "$tmp_file"
    else
        # Append at end
        cat "$i3_config" > "$tmp_file"
        echo "$insert_block" >> "$tmp_file"
    fi

    # Show diff
    echo ""
    echo "Proposed changes to $i3_config:"
    echo ""
    if command -v git &> /dev/null; then
        git diff --no-index "$i3_config" "$tmp_file" || true
    else
        diff -u --color=always "$i3_config" "$tmp_file" || true
    fi
    echo ""

    # Ask for confirmation
    read -p "Apply these changes? [y/N] " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cp "$tmp_file" "$i3_config"
        chown "$real_user":"$real_user" "$i3_config"
        info "i3 autostart configured"
    else
        warn "Skipped i3 configuration"
    fi

    rm -f "$tmp_file"
}

setup_log() {
    info "Setting up log file..."

    touch "$LOG_FILE"
    chmod 666 "$LOG_FILE"
}

reload_udev() {
    local real_user="${SUDO_USER:-$USER}"

    info "Reloading udev rules..."

    udevadm control --reload-rules
    udevadm trigger

    # Reapply layouts after udev trigger (as user for notifications)
    sudo -u "$real_user" "$INSTALL_DIR/kbd-auto-layout" reload 2>/dev/null || true
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
    setup_i3_autostart
    setup_log
    reload_udev

    show_summary
}

main "$@"
