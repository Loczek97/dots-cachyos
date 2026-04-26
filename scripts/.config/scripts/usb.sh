#!/usr/bin/env bash

CACHE_FILE="/tmp/usb_notify_cache"
touch "$CACHE_FILE"

notify_usb() {
  local action=$1
  local model=$2
  local vendor=$3
  local label=$4
  local dev=$5
  local serial=$6

  local current_time=$(date +%s)
  local cache_key="${action}_${serial}"
  [ -z "$serial" ] && cache_key="${action}_${model}_${vendor}" # fallback jeśli brak seriala

  if [ -f "$CACHE_FILE" ]; then
    local last_entry=$(cat "$CACHE_FILE")
    local last_key="${last_entry%|*}"
    local last_time="${last_entry#*|}"

    if [ "$cache_key" == "$last_key" ] && [ $((current_time - last_time)) -lt 2 ]; then
      return
    fi
  fi
  echo "${cache_key}|${current_time}" >"$CACHE_FILE"

  if [ "$action" == "add" ] && ([ -z "$model" ] || [ -z "$vendor" ]); then
    eval $(udevadm info -q property -n "$dev" | grep -E "^(ID_MODEL|ID_VENDOR|ID_FS_LABEL|ID_SERIAL|ID_MODEL_ID)=")
    model=${ID_MODEL:-$model}
    vendor=${ID_VENDOR:-$vendor}
    label=${ID_FS_LABEL:-$label}
  fi

  local display_name=""
  [ -n "$vendor" ] && display_name+="$vendor "
  [ -n "$model" ] && display_name+="$model"
  [ -z "$display_name" ] && display_name="Urządzenie USB"

  if [ "$action" == "add" ]; then
    local detail="Ścieżka: $dev"
    [ -n "$label" ] && detail="Etykieta: $label\n$detail"
    notify-send -a "System" -i "drive-removable-media" "Podłączono urządzenie USB" "$display_name\n$detail"
  elif [ "$action" == "remove" ]; then
    notify-send -a "System" -i "drive-removable-media" "Odłączono urządzenie USB" "$display_name"
  fi
}

udevadm monitor --subsystem-match=block --property | while read -r line; do
  [[ "$line" == ID_MODEL=* ]] && ID_MODEL="${line#*=}"
  [[ "$line" == ID_VENDOR=* ]] && ID_VENDOR="${line#*=}"
  [[ "$line" == ID_FS_LABEL=* ]] && ID_FS_LABEL="${line#*=}"
  [[ "$line" == ID_SERIAL=* ]] && ID_SERIAL="${line#*=}"
  [[ "$line" == DEVNAME=* ]] && DEVNAME="${line#*=}"
  [[ "$line" == DEVTYPE=* ]] && DEVTYPE="${line#*=}"
  [[ "$line" == ACTION=* ]] && ACTION="${line#*=}"

  if [[ "$line" == UDEV* ]]; then
    if [[ "$DEVTYPE" == "partition" || "$DEVTYPE" == "disk" ]]; then
      if [ "$ACTION" == "add" ]; then
        (sleep 0.6 && notify_usb "add" "$ID_MODEL" "$ID_VENDOR" "$ID_FS_LABEL" "$DEVNAME" "$ID_SERIAL") &
      elif [ "$ACTION" == "remove" ]; then
        notify_usb "remove" "$ID_MODEL" "$ID_VENDOR" "$ID_FS_LABEL" "$DEVNAME" "$ID_SERIAL"
      fi
    fi

    ID_MODEL=""
    ID_VENDOR=""
    ID_FS_LABEL=""
    ID_SERIAL=""
    DEVNAME=""
    DEVTYPE=""
    ACTION=""
  fi
done
