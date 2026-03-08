#!/bin/bash

# Config
STEP=5
MIN=0
MAX=100

# Get current volume from default line
CURRENT=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\d+?(?=%)' | head -n1)

# Arguments: up / down
case "$1" in
  up)
    NEW=$((CURRENT + STEP))
    ;;
  down)
    NEW=$((CURRENT - STEP))
    ;;
  *)
    echo "Użycie: $0 {up|down}"
    exit 1
    ;;
esac

# Restrictions
if [ "$NEW" -gt "$MAX" ]; then
  NEW=$MAX
elif [ "$NEW" -lt "$MIN" ]; then
  NEW=$MIN
fi

# Ustaw nową głośność
pactl set-sink-volume @DEFAULT_SINK@ "${NEW}%"
echo "Volume set to ${NEW}%"
