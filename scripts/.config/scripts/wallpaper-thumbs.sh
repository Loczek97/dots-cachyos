#!/usr/bin/env bash

THUMB_DIR="$HOME/.cache/wallpaper_picker/thumbs"
MARKER_DIR="$HOME/.cache/wallpaper_picker/colors_markers"
SRC_DIR="$HOME/.config/backgrounds"

mkdir -p "$THUMB_DIR"
mkdir -p "$MARKER_DIR"

# 1. Process Images
for img in "$SRC_DIR"/*.{jpg,jpeg,png,webp,gif}; do
    [ -e "$img" ] || continue
    filename=$(basename "$img")
    thumb="$THUMB_DIR/$filename"
    marker_prefix="$MARKER_DIR/$filename"
    
    # Generate thumbnail
    if [ ! -f "$thumb" ]; then
        magick "$img" -resize x420 -quality 70 "$thumb"
    fi

    # Generate color marker if missing
    if [[ -z $(ls "${marker_prefix}_HEX_"* 2>/dev/null) ]]; then
        # Use %[pixel:p{0,0}] to get hex color safely in Magick v7
        hex=$(magick "$thumb" -scale 1x1\! -alpha off -format "%[pixel:p{0,0}]" info:)
        # Remove '#' and take only 6 chars
        hex_short=$(echo "$hex" | sed 's/#//' | head -c 6)
        touch "${marker_prefix}_HEX_${hex_short}"
    fi
done

# 2. Process Videos
for vid in "$SRC_DIR"/*.{mp4,mkv,mov,webm}; do
    [ -e "$vid" ] || continue
    filename=$(basename "$vid")
    thumb="$THUMB_DIR/000_$filename"
    thumb_base="${thumb%.*}"
    
    if [ ! -f "${thumb_base}.jpg" ]; then
        ffmpeg -y -ss 00:00:05 -i "$vid" -vframes 1 -f image2 -q:v 2 "${thumb_base}.jpg" > /dev/null 2>&1
        hex=$(magick "${thumb_base}.jpg" -scale 1x1\! -alpha off -format "%[pixel:p{0,0}]" info:)
        hex_short=$(echo "$hex" | sed 's/#//' | head -c 6)
        touch "$MARKER_DIR/000_${filename}_HEX_${hex_short}"
    fi
done
