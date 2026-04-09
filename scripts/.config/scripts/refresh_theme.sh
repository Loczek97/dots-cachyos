#!/usr/bin/env bash

sync

# Hyprland
hyprctl reload
sleep 0.1

# Kitty
killall -SIGUSR1 kitty 2>/dev/null

# Rofi & Notifications
pkill rofi 2>/dev/null
/home/michal/.config/swaync/reload_swaync.sh 2>/dev/null

# Eww
eww --config /home/michal/.config/eww/bar reload 2>/dev/null

# QuickShell (last)
nohup /home/michal/.config/scripts/qs_manager.sh restart >/dev/null 2>&1 &
