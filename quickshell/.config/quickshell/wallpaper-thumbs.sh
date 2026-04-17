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
    if [ ! -f "${marker_prefix}_HEX_"* ]; then
        # Extract dominant color directly to hex without pipes
        hex=$(magick "$thumb" -scale 1x1\! -alpha off -format "%[hex]" info:)
        # Take only last 6 chars to avoid potential # or alpha
        hex_short=$(echo "$hex" | tail -c 7)
        touch "${marker_prefix}_HEX_${hex_short}"
    fi
done

# 2. Process Videos
for vid in "$SRC_DIR"/*.{mp4,mkv,mov,webm}; do
    [ -e "$vid" ] || continue
    filename=$(basename "$vid")
    thumb="$THUMB_DIR/000_$filename"
    
    if [ ! -f "${thumb%.*}.jpg" ]; then
        ffmpeg -y -ss 00:00:05 -i "$vid" -vframes 1 -f image2 -q:v 2 "${thumb%.*}.jpg" > /dev/null 2>&1
        hex=$(magick "${thumb%.*}.jpg" -scale 1x1\! -alpha off -format "%[hex]" info:)
        hex_short=$(echo "$hex" | tail -c 7)
        touch "$MARKER_DIR/000_${filename}_HEX_${hex_short}"
    fi
done
