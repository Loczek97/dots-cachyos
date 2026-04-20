#!/bin/bash

WALLPAPER="$1"
QML_DIR="$HOME/.config/quickshell/desktopclock"

python3 "$HOME/.config/quickshell/scripts/clock_position.py" "$WALLPAPER" "$QML_DIR/clock_pos.json"

pkill -f "quickshell.*DesktopClock.qml"

quickshell -p "$QML_DIR/DesktopClock.qml" > /dev/null 2>&1 & disown