#!/usr/bin/env bash

THUMB_DIR="$HOME/.cache/wallpaper_picker/thumbs"
MARKER_DIR="$HOME/.cache/wallpaper_picker/colors_markers"
SRC_DIR="$HOME/.config/backgrounds"

mkdir -p "$THUMB_DIR"
mkdir -p "$MARKER_DIR"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/convert_wallpapers.sh" "$SRC_DIR"

shopt -s nullglob
for img in "$SRC_DIR"/*.{jpg,jpeg,png,webp,gif}; do
  [ -e "$img" ] || continue
  filename=$(basename "$img")
  thumb="$THUMB_DIR/$filename"
  marker_prefix="$MARKER_DIR/$filename"

  if [ ! -f "$thumb" ]; then
    magick "${img}[0]" -resize x420 -quality 70 "jpg:$thumb"
  fi

  if [[ -z $(ls "${marker_prefix}_HEX_"* 2>/dev/null) ]]; then
    hex=$(magick "${img}[0]" -scale 1x1\! -alpha off -format "%[pixel:p{0,0}]" info:)
    hex_short=$(echo "$hex" | sed 's/#//' | head -c 6)
    touch "${marker_prefix}_HEX_${hex_short}"
  fi
done

for vid in "$SRC_DIR"/*.{mp4,mkv,mov,webm}; do
  [ -e "$vid" ] || continue
  filename=$(basename "$vid")
  thumb="$THUMB_DIR/000_$filename"
  thumb_base="${thumb%.*}"

  if [ ! -f "${thumb_base}.jpg" ]; then
    ffmpeg -y -ss 00:00:05 -i "$vid" -vframes 1 -f image2 -q:v 2 "${thumb_base}.jpg" >/dev/null 2>&1
    hex=$(magick "${thumb_base}.jpg" -scale 1x1\! -alpha off -format "%[pixel:p{0,0}]" info:)
    hex_short=$(echo "$hex" | sed 's/#//' | head -c 6)
    touch "$MARKER_DIR/000_${filename}_HEX_${hex_short}"
  fi
done
