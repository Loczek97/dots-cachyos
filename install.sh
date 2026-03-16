#!/bin/bash

# --- Dotfiles Installation Script (Arch-based) ---

set -e

echo "=== Starting installation of Dotfiles dependencies ==="

# Check for AUR helper
if command -v yay >/dev/null 2>&1; then
    AUR_HELPER="yay"
elif command -v paru >/dev/null 2>&1; then
    AUR_HELPER="paru"
else
    echo "AUR helper not found. Installing yay..."
    sudo pacman -S --needed --noconfirm git base-devel
    git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
    (cd /tmp/yay-bin && makepkg -si --noconfirm)
    rm -rf /tmp/yay-bin
    AUR_HELPER="yay"
fi

# List of packages to install
PACKAGES=(
    # System & Window Manager
    "hyprland"
    "hyprland-polkit-agent"
    "hypridle"
    "hyprlock"
    "xdg-desktop-portal-hyprland"
    "xdg-desktop-portal"
    "qt6-wayland"
    "qt6-declarative"
    "qt6-svg"
    "qt5ct"
    "qt6ct"

    # Shell & UI Elements
    "zsh"
    "zsh-theme-powerlevel10k-git"
    "cachyos-zsh-config"
    "nvm"
    "awww"
    "swaync"
    "eww-wayland"
    "quickshell-git"
    "rofi-wayland"
    "rofi-emoji"
    "wlogout"
    "wofi"
    "matugen-bin"

    # Terminal & Editor
    "kitty"
    "yazi"

    # Browser
    "zen-browser-bin"

    # File Management
    "thunar"
    "gvfs"
    "gvfs-mtp"
    "gvfs-afc"
    "tumbler"
    "thunar-archive-plugin"
    "thunar-volman"
    "ffmpegthumbnailer"

    # Media & Visuals
    "cava"
    "fastfetch"
    "swappy"
    "grim"
    "slurp"
    "wl-clipboard"
    "playerctl"
    "imagemagick"
    "stow"

    # Hardware Control & Networking
    "brightnessctl"
    "libpulse"
    "networkmanager"
    "bluez"
    "bluez-utils"
    "blueman"
    "iw"
    "iproute2"

    # Fonts
    "ttf-jetbrains-mono-nerd"
    "ttf-iosevka-nerd"
    "otf-font-awesome"

    # Additional dependencies
    "curl"
    "jq"
    "python"
    "python-requests"
    "betterdiscordctl"
)

echo "--- Installing packages ---"
$AUR_HELPER -S --needed --noconfirm "${PACKAGES[@]}"

echo "--- Setting up Zsh ---"
chsh -s $(which zsh)

echo "--- Setting up NVM ---"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" || {
    source /usr/share/nvm/init-nvm.sh 2>/dev/null || true
}

echo "--- Enabling Services ---"
sudo systemctl enable --now NetworkManager
sudo systemctl enable --now bluetooth

echo "--- Setting up Hyprland Plugins (hyprpm) ---"
hyprpm update

echo "--- Installation Complete ---"
echo "You can now link your dotfiles to ~/.config using 'stow' or manual symlinks."
