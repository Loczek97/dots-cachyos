#!/bin/bash

# Config
MIN=10
MAX=100
STEP=10

# Get current brightness in %
CURRENT=$(brightnessctl g)
MAX_RAW=$(brightnessctl m)
CURRENT_PERCENT=$(( CURRENT * 100 / MAX_RAW ))

# Parsing args
case "$1" in
  up)
    NEW=$(( CURRENT_PERCENT + STEP ))
    ;;
  down)
    NEW=$(( CURRENT_PERCENT - STEP ))
    ;;
  *)
    echo "Usage: $0 {up|down}"
    exit 1
    ;;
esac

# Ograniczenia
if [ "$NEW" -gt "$MAX" ]; then
  NEW=$MAX
elif [ "$NEW" -lt "$MIN" ]; then
  NEW=$MIN
fi

# Set new brightness
brightnessctl s "${NEW}%"
echo "Brightness set to ${NEW}%"
