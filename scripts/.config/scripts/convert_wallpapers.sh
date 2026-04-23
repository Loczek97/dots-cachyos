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

  if [[ "$lower_ext" == "jpg" || "$lower_ext" == "jpeg" ]]; then
    continue
  fi

  mime=$(file --mime-type -b "$f")

  if [[ "$mime" == image/* ]]; then
    new_name="${filename%.*}.jpg"

    if magick "$f" "$new_name"; then
      rm "$f"
    else
      echo "  [ERROR] Failed to convert: $filename"
    fi
  fi
done
