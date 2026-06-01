#!/usr/bin/env bash

SCAN_LOG="$HOME/.cache/bt_scan.log"
PID_FILE="$HOME/.cache/bt_scan_pid"
CACHE_DIR="/tmp/quickshell_network_cache"
mkdir -p "$CACHE_DIR"

get_icon() {
    local type=$(echo "$1" | tr '[:upper:]' '[:lower:]')
    local name=$(echo "$2" | tr '[:upper:]' '[:lower:]')
    if [[ "$type" == *"headset"* ]] || [[ "$type" == *"headphone"* ]] || [[ "$name" == *"headphone"* ]] || [[ "$name" == *"buds"* ]] || [[ "$name" == *"pods"* ]]; then echo "🎧"
    elif [[ "$type" == *"audio"* ]] || [[ "$type" == *"speaker"* ]] || [[ "$type" == *"card"* ]] || [[ "$name" == *"speaker"* ]]; then echo "蓼"
    elif [[ "$type" == *"phone"* ]] || [[ "$name" == *"phone"* ]] || [[ "$name" == *"iphone"* ]] || [[ "$name" == *"android"* ]]; then echo ""
    elif [[ "$type" == *"mouse"* ]] || [[ "$name" == *"mouse"* ]]; then echo ""
    elif [[ "$type" == *"keyboard"* ]] || [[ "$name" == *"keyboard"* ]]; then echo ""
    elif [[ "$type" == *"controller"* ]] || [[ "$name" == *"controller"* ]]; then echo ""
    else echo ""
    fi
}

get_audio_profile() {
    local mac="$1"
    local mac_us="${mac//:/_}"
    local card="bluez_card.$mac_us"
    
    local cards_info=$(pactl list cards 2>/dev/null)
    if ! echo "$cards_info" | grep -q "$card"; then echo "Nieznany"; return; fi

    local active=$(echo "$cards_info" | awk -v c="$card" '$0~"Name: "c{f=1} f&&/^[\t ]*Active Profile:/{print $3; exit}')
    
    if [[ -z "$active" || "$active" == "off" ]]; then echo "Brak"; return; fi
    
    local desc="Połączono"
    if [[ "$active" == *"a2dp"* ]]; then desc="Wysoka jakość (A2DP)"; fi
    if [[ "$active" == *"headset"* || "$active" == *"hfp"* ]]; then desc="Zestaw słuchawkowy (HFP)"; fi
    
    echo "$desc"
}

get_status() {
    power="off"
    if bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then power="on"; fi

    connected_json="null"
    devices_json="[]"

    if [ "$power" == "on" ]; then
        connected_mac=""

        # Get connected device
        connected_info=$(bluetoothctl devices Connected 2>/dev/null | head -n1)
        if [ -n "$connected_info" ]; then
            local rest="${connected_info#Device }"
            connected_mac="${rest:0:17}"
            if [ -n "$connected_mac" ]; then
                CACHE_FILE="$CACHE_DIR/bt_stat_${connected_mac//:/_}"

                if [ -f "$CACHE_FILE" ]; then
                    source "$CACHE_FILE"
                else
                    local name="${rest:18}"
                    local info=$(bluetoothctl info "$connected_mac" 2>/dev/null)
                    local icon_type=""
                    if [[ "$info" =~ Icon:[[:space:]]*(.*) ]]; then
                        icon_type="${BASH_REMATCH[1]}"
                        icon_type="${icon_type%"${icon_type##*[![:space:]]}"}"
                    fi
                    icon=$(get_icon "$icon_type" "$name")
                    profile=$(get_audio_profile "$connected_mac")
                    
                    cat > "$CACHE_FILE" << EOF
CACHE_NAME="$name"
CACHE_ICON="$icon"
CACHE_PROFILE="$profile"
EOF
                    CACHE_NAME="$name"
                    CACHE_ICON="$icon"
                    CACHE_PROFILE="$profile"
                fi
                
                if [ -z "$info" ]; then
                    info=$(bluetoothctl info "$connected_mac" 2>/dev/null)
                fi
                local bat="0"
                if [[ "$info" =~ [Bb]attery[[:space:]]+[Pp]ercentage:[[:space:]]*0x[0-9a-fA-F]+[[:space:]]*\(([0-9]+)\) ]]; then
                    bat="${BASH_REMATCH[1]}"
                elif [[ "$info" =~ [Bb]attery[[:space:]]+[Pp]ercentage:[[:space:]]*\(?([0-9]+)\)? ]]; then
                    bat="${BASH_REMATCH[1]}"
                fi

                connected_json=$(jq -n -c \
                                    --arg id "$connected_mac" \
                                    --arg name "$CACHE_NAME" \
                                    --arg mac "$connected_mac" \
                                    --arg icon "$CACHE_ICON" \
                                    --arg bat "$bat" \
                                    --arg profile "$CACHE_PROFILE" \
                                    '{id: $id, name: $name, mac: $mac, icon: $icon, battery: $bat, profile: $profile}')
            fi
        fi

        # Get paired devices once
        local paired_list=$(bluetoothctl paired-devices 2>/dev/null)

        # Get all devices
        devices_json=$(while IFS= read -r line; do
            [ -z "$line" ] && continue
            
            local rest="${line#Device }"
            local mac="${rest:0:17}"
            local name="${rest:18}"
            
            [ -z "$mac" ] && continue
            [[ "$mac" == "$connected_mac" ]] && continue
            
            local icon=$(get_icon "unknown" "$name")
            
            local action="Sparuj"
            if echo "$paired_list" | grep -Fq "$mac"; then
                action="Połącz"
            fi
            
            printf "%s\t%s\t%s\t%s\t%s\n" "$mac" "$name" "$mac" "$icon" "$action"
        done < <(bluetoothctl devices 2>/dev/null) | jq -R -s -c '
          split("\n")
          | map(
              select(length > 0)
              | split("\t")
              | {
                  id: .[0],
                  name: .[1],
                  mac: .[2],
                  icon: .[3],
                  action: .[4]
                }
            )
          | sort_by(if .action == "Połącz" then 0 else 1 end)
        ')
        [ -z "$devices_json" ] && devices_json="[]"
    fi

    jq -n -c \
        --arg power "$power" \
        --argjson connected "${connected_json:-null}" \
        --argjson devices "${devices_json:-[]}" \
        '{power: $power, connected: $connected, devices: $devices}'
}

toggle_power() {
    if bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
        bluetoothctl power off 2>/dev/null
    else
        bluetoothctl power on 2>/dev/null
    fi
    sleep 0.5
}

connect_dev() {
    local mac="$1"
    if [ -f "$PID_FILE" ]; then kill -STOP $(cat "$PID_FILE") 2>/dev/null; fi
    bluetoothctl trust "$mac" > /dev/null 2>&1
    bluetoothctl connect "$mac" > /dev/null 2>&1
    if [ -f "$PID_FILE" ]; then kill -CONT $(cat "$PID_FILE") 2>/dev/null; fi
}

disconnect_dev() {
    local mac="$1"
    rm -f "/tmp/quickshell_network_cache/bt_stat_${mac//:/_}" 2>/dev/null
    bluetoothctl disconnect "$mac" > /dev/null 2>&1
}

cmd="$1"
case $cmd in
    --status) get_status ;;
    --toggle) toggle_power ;;
    --connect) connect_dev "$2" ;;
    --disconnect) disconnect_dev "$2" ;;
    *) get_status ;;
esac