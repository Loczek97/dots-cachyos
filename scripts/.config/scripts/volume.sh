#!/bin/bash
case $1 in
up)
  pactl set-sink-volume @DEFAULT_SINK@ +1%
  ;;
down)
  pactl set-sink-volume @DEFAULT_SINK@ -1%
  ;;
mute)
  pactl set-sink-mute @DEFAULT_SINK@ toggle
  ;;
esac
