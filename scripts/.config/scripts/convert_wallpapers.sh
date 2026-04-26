#!/usr/bin/env bash

TARGET_DIR="${1:-$HOME/.config/backgrounds}"

if [ ! -d "$TARGET_DIR" ]; then
  echo "ERROR: TARGET_DIR: $TARGET_DIR doesn't exist."
  exit 1
fi

cd "$TARGET_DIR" || exit

shopt -s nullglob nocaseglob
files=(*)

for f in "${files[@]}"; do
  [ -f "$f" ] || continue

  filename=$(basename "$f")
  extension="${filename##*.}"
  lower_ext="${extension,,}"

  if [[ "$lower_ext" == "jpg" || "$lower_ext" == "jpeg" || "$lower_ext" == "gif" ]]; then
    continue
  fi

  mime=$(file --mime-type -b "$f")

  if [[ "$mime" == image/* && "$mime" != "image/gif" ]]; then
    new_name="${filename%.*}.jpg"

    if magick "${f}[0]" "$new_name"; then
      rm "$f"
    else
      echo "  [ERROR] Failed to convert: $filename"
    fi
  fi
done
