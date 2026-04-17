#!/usr/bin/env bash

SAFE_NAME="$1"
IS_VIDEO="$2"
TRANS="$3"
IS_SEARCH_FLAG="$4"

# Use transition from old config or default
if [ -z "$TRANS" ]; then TRANS="grow"; fi
# Old duration was 1.0s
DURATION=1.0

SRC_DIR="$HOME/.config/backgrounds"
CACHE_ROOT="$HOME/.cache/wallpaper_picker"
MAP_FILE="$CACHE_ROOT/search_map.txt"
LOG_FILE="/tmp/qs_wall_apply.log"

exec > "$LOG_FILE" 2>&1
echo "=== Apply Wallpaper: $SAFE_NAME ==="

# Znajdź URL w mapie
URL=$(grep "^$SAFE_NAME|" "$MAP_FILE" | cut -d'|' -f2- | head -n 1)

if [ -n "$URL" ]; then
    DEST_FILE="$SRC_DIR/$SAFE_NAME"
    echo "Downloading from Wallhaven: $URL"
    curl -L -s -A "Mozilla/5.0" "$URL" -o "$DEST_FILE"
    
    /usr/bin/awww img "$DEST_FILE" --transition-type "$TRANS" --transition-pos 0.5,0.5 --transition-fps 144 --transition-duration "$DURATION"
    ln -sf "$DEST_FILE" "$HOME/.config/current_bg"
    # Copy exactly from wallpaper_old
    matugen image "$DEST_FILE" --mode dark --source-color-index 0 || true
else
    # Lokalna tapeta
    CLEAN_NAME=$(echo "$SAFE_NAME" | sed 's/^000_//')
    FULL_PATH="$SRC_DIR/$CLEAN_NAME"
    
    /usr/bin/awww img "$FULL_PATH" --transition-type "$TRANS" --transition-pos 0.5,0.5 --transition-fps 144 --transition-duration "$DURATION"
    ln -sf "$FULL_PATH" "$HOME/.config/current_bg"
    # Copy exactly from wallpaper_old
    matugen image "$FULL_PATH" --mode dark --source-color-index 0 || true
fi

# Pass the background path to the clock script
CURRENT_BG="$HOME/.config/current_bg"
bash "$HOME/.config/quickshell/scripts/update_clock.sh" "$CURRENT_BG"
echo "Done."
