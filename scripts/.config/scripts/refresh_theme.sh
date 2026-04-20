#!/usr/bin/env bash

sync

# Hyprland
hyprctl reload
sleep 0.1

# Refresh colors for GTK/Quickshell/Kitty
bash "$HOME/.config/quickshell/wallpapers-szablon-imperative-dots/matugen_reload.sh"

# GTK & Libadwaita (Nautilus)
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
gsettings set org.gnome.desktop.interface gtk-theme "Adwaita"
gsettings set org.gnome.desktop.interface icon-theme "Adwaita"

# Kitty
killall -SIGUSR1 kitty 2>/dev/null

# Rofi & Notifications
pkill rofi 2>/dev/null
/home/michal/.config/swaync/reload_swaync.sh 2>/dev/null

# Eww
eww --config /home/michal/.config/eww/bar reload 2>/dev/null

# QuickShell (last)
nohup /home/michal/.config/scripts/qs_manager.sh restart >/dev/null 2>&1 &
