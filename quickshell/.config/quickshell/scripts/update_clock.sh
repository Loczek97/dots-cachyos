#!/bin/bash

WALLPAPER="$1"
QML_DIR="$HOME/.config/quickshell/desktopclock"

python3 "$HOME/.config/quickshell/scripts/clock_position.py" "$WALLPAPER" "$QML_DIR/clock_pos.json"