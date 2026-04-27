#!/usr/bin/env bash
exec 2>/tmp/wall_error.log
set -x

WALLPAPER_PATH="$1"
TRANSITION="${2:-grow}"
MIME_TYPE=$(file --mime-type -b "$WALLPAPER_PATH")

export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

ln -sf "$WALLPAPER_PATH" "$HOME/.config/current_bg"

pkill mpvpaper

ICON_PATH="$WALLPAPER_PATH"

if [[ "$MIME_TYPE" == video/* ]]; then
  TEMP_FRAME="/tmp/wallpaper_frame.png"
  ffmpeg -y -i "$WALLPAPER_PATH" -frames:v 1 -update 1 "$TEMP_FRAME" >/dev/null 2>&1
  matugen image "$TEMP_FRAME" --mode dark --source-color-index 0

  ICON_PATH="$TEMP_FRAME"
  ANALYSIS_PATH="$TEMP_FRAME"

  swww clear
  mpvpaper -o 'loop --hwdec=auto --no-audio --cache=no --demuxer-max-bytes=10M --vd-lavc-threads=1 --profile=fast --vd-lavc-fast --swapchain-depth=1' '*' "$WALLPAPER_PATH" &
  disown
else
  swww query || swww-daemon &
  awww img "$WALLPAPER_PATH" --transition-type "$TRANSITION" --transition-pos 0.5,0.5 --transition-fps 144 --transition-duration 1
  matugen image "$WALLPAPER_PATH" --mode dark --source-color-index 0
  ANALYSIS_PATH="$WALLPAPER_PATH"
fi

if [ -f "$HOME/.config/quickshell/scripts/update_clock.sh" ]; then
  bash "$HOME/.config/quickshell/scripts/update_clock.sh" "$ANALYSIS_PATH" &
  disown
fi

notify-send "Tapeta Zmieniona" "$(basename "$WALLPAPER_PATH")" --app-name="Menadżer tapet" --expire-time=2000 --icon="$ICON_PATH"
