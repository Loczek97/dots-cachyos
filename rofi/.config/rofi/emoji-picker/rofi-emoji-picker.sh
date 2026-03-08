#!/usr/bin/env bash

# Path to specific rofi config
rofi_config="$HOME/.config/rofi/emoji-picker/config.rasi"

rofi -show emoji -modi emoji -config "$rofi_config"
