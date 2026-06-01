#!/usr/bin/env bash

## WIFI
get_wifi_status() {
    nmcli -t -f WIFI g 2>/dev/null || echo "disabled"
}

get_wifi_ssid() {
    local ssid=$(nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | grep -E '^(yes|tak)' | head -1 | cut -d: -f2)
    if [ -z "$ssid" ]; then
        echo ""
    else
        echo "$ssid"
    fi
}

get_kb_layout() {
    local layout=$(hyprctl devices -j | jq -r '.keyboards[] | select(.main == true) | .active_keymap' | head -n1)
    echo "$layout" | cut -c1-2 | tr '[:lower:]' '[:upper:]'
}

get_wifi_icon() {
    local status=$(get_wifi_status)
    local ssid=$(get_wifi_ssid)
    
    if [ "$status" = "enabled" ]; then
        if [ -n "$ssid" ]; then
            local signal=$(get_wifi_strength)
            if [ "$signal" -ge 75 ]; then
                echo "󰤨"
            elif [ "$signal" -ge 50 ]; then
                echo "󰤥"
            elif [ "$signal" -ge 25 ]; then
                echo "󰤢"
            else
                echo "󰤟"
            fi
        else
            echo "󰤯"
        fi
    else
        echo "󰤮"
    fi
}

get_wifi_strength() {
    local signal=$(nmcli -f IN-USE,SIGNAL dev wifi 2>/dev/null | grep '^\*' | awk '{print $2}')
    echo "${signal:-0}"
}

toggle_wifi() {
    if [ "$(nmcli -t -f WIFI g 2>/dev/null)" = "enabled" ]; then
        nmcli radio wifi off
        notify-send -u low -i network-wireless-disabled "WiFi" "Disabled"
    else
        nmcli radio wifi on
        notify-send -u low -i network-wireless-enabled "WiFi" "Enabled"
    fi
}

## BLUETOOTH
get_bt_status() {
    if [ ! -d /sys/class/bluetooth ]; then
        echo "off"
        return
    fi
    if timeout 0.5 bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
        echo "on"
    else
        echo "off"
    fi
}

get_bt_icon() {
    local status=$(get_bt_status)
    
    if [ "$status" = "on" ]; then
        if timeout 0.5 bluetoothctl devices Connected 2>/dev/null | grep -q "Device"; then
            echo "󰂱"
        else
            echo "󰂯"
        fi
    else
        echo "󰂲"
    fi
}

get_bt_connected_device() {
    if [ "$(get_bt_status)" = "on" ]; then
        local device=$(timeout 0.5 bluetoothctl devices Connected 2>/dev/null | head -n1 | cut -d' ' -f3-)
        if [ -z "$device" ]; then
            echo "Disconnected"
        else
            echo "$device"
        fi
    else
        echo "Off"
    fi
}

toggle_bt() {
    local status=$(get_bt_status)
    if [ "$status" = "on" ]; then
        timeout 2 bluetoothctl power off 2>/dev/null
        notify-send -u low -i bluetooth-disabled "Bluetooth" "Disabled"
    else
        timeout 2 bluetoothctl power on 2>/dev/null
        notify-send -u low -i bluetooth-active "Bluetooth" "Enabled"
    fi
}

## BRIGHTNESS
get_brightness() {
    if command -v brightnessctl &> /dev/null; then
        local percent=$(brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d '%')
        echo "${percent:-50}"
    elif command -v light &> /dev/null; then
        local percent=$(light -G 2>/dev/null | cut -d. -f1)
        echo "${percent:-50}"
    else
        echo "50"
    fi
}

## AUDIO
get_volume() {
    if command -v pamixer &> /dev/null; then
        pamixer --get-volume 2>/dev/null || echo "50"
    elif command -v pactl &> /dev/null; then
        pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -oP '\d+%' | head -n1 | tr -d '%' || echo "50"
    else
        echo "50"
    fi
}

is_muted() {
    if command -v pamixer &> /dev/null; then
        if pamixer --get-mute 2>/dev/null | grep -q "true"; then echo "true"; else echo "false"; fi
    elif command -v pactl &> /dev/null; then
        if pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | grep -q "yes"; then echo "true"; else echo "false"; fi
    else
        echo "false"
    fi
}

get_volume_icon() {
    local vol=$(get_volume | tr -cd '0-9')
    local muted=$(is_muted)
    [ -z "$vol" ] && vol=0
    if [ "$muted" = "true" ]; then echo "󰝟"; elif [ "$vol" -ge 70 ]; then echo "󰕾"; elif [ "$vol" -ge 30 ]; then echo "󰖀"; elif [ "$vol" -gt 0 ]; then echo "󰕿"; else echo "󰝟"; fi
}

## BATTERY
get_battery_percent() {
    if [ -f /sys/class/power_supply/BAT*/capacity ]; then
        cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n1 || echo "100"
    else
        echo "100"
    fi
}

get_battery_icon() {
    local percent=$(get_battery_percent)
    if [ "$percent" -ge 90 ]; then echo "󰁹"; elif [ "$percent" -ge 70 ]; then echo "󰂁"; elif [ "$percent" -ge 50 ]; then echo "󰁿"; elif [ "$percent" -ge 30 ]; then echo "󰁽"; else echo "󰁺"; fi
}

get_all_fast() {
    local vol="50"
    local muted="false"
    if command -v pamixer &> /dev/null; then
        vol=$(pamixer --get-volume 2>/dev/null || echo "50")
        muted=$(pamixer --get-mute 2>/dev/null || echo "false")
    elif command -v pactl &> /dev/null; then
        vol=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -oP '\d+%' | head -n1 | tr -d '%' || echo "50")
        muted=$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | grep -q "yes" && echo "true" || echo "false")
    fi

    local vol_icon="󰕾"
    if [ "$muted" = "true" ]; then vol_icon="󰝟"
    elif [ "$vol" -ge 70 ]; then vol_icon="󰕾"
    elif [ "$vol" -ge 30 ]; then vol_icon="󰖀"
    elif [ "$vol" -gt 0 ]; then vol_icon="󰕿"
    else vol_icon="󰝟"
    fi

    local layout=$(hyprctl devices -j | jq -r '.keyboards[] | select(.main == true) | .active_keymap' | head -n1)
    layout=$(echo "$layout" | cut -c1-2 | tr '[:lower:]' '[:upper:]')

    echo "$vol"
    echo "$vol_icon"
    echo "${layout:-PL}"
    echo "$muted"
}

get_all_slow() {
    local wifi_status="disabled"
    local wifi_ssid=""
    local wifi_icon="󰤮"

    if command -v nmcli &> /dev/null; then
        wifi_status=$(nmcli -t -f WIFI g 2>/dev/null || echo "disabled")
        if [ "$wifi_status" = "enabled" ]; then
            local active_line=$(nmcli -t -f ACTIVE,SSID,SIGNAL dev wifi 2>/dev/null | grep -E '^(yes|tak)' | head -n1)
            if [ -n "$active_line" ]; then
                wifi_ssid=$(echo "$active_line" | cut -d: -f2)
                local strength=$(echo "$active_line" | cut -d: -f3)
                strength=${strength:-0}
                if [ "$strength" -ge 75 ]; then wifi_icon="󰤨"
                elif [ "$strength" -ge 50 ]; then wifi_icon="󰤥"
                elif [ "$strength" -ge 25 ]; then wifi_icon="󰤢"
                else wifi_icon="󰤟"
                fi
            else
                wifi_icon="󰤯"
            fi
        fi
    fi

    local bt_status="off"
    local bt_icon="󰂲"
    local bt_connected="Disconnected"

    if [ -d /sys/class/bluetooth ]; then
        if timeout 0.2 bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
            bt_status="on"
            bt_icon="󰂯"
            local dev=$(timeout 0.2 bluetoothctl devices Connected 2>/dev/null | head -n1 | cut -d' ' -f3-)
            if [ -n "$dev" ]; then
                bt_icon="󰂱"
                bt_connected="$dev"
            fi
        fi
    fi

    local bat_percent="100"
    if [ -f /sys/class/power_supply/BAT*/capacity ]; then
        bat_percent=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n1 || echo "100")
    fi
    local bat_icon="󰁹"
    if [ "$bat_percent" -ge 90 ]; then bat_icon="󰁹"
    elif [ "$bat_percent" -ge 70 ]; then bat_icon="󰂁"
    elif [ "$bat_percent" -ge 50 ]; then bat_icon="󰁿"
    elif [ "$bat_percent" -ge 30 ]; then bat_icon="󰁽"
    else bat_icon="󰁺"
    fi

    echo "$wifi_status"
    echo "$wifi_icon"
    echo "$wifi_ssid"
    echo "$bt_status"
    echo "$bt_icon"
    echo "$bt_connected"
    echo "$bat_percent"
    echo "$bat_icon"
}

## EXECUTION
cmd="$1"
case $cmd in
    --wifi-status) get_wifi_status ;;
    --wifi-ssid) get_wifi_ssid ;;
    --wifi-icon) get_wifi_icon ;;
    --bt-status) get_bt_status ;;
    --bt-icon) get_bt_icon ;;
    --bt-connected) get_bt_connected_device ;;
    --volume) get_volume ;;
    --volume-icon) get_volume_icon ;;
    --is-muted) is_muted ;;
    --battery-percent) get_battery_percent ;;
    --battery-icon) get_battery_icon ;;
    --kb-layout) get_kb_layout ;;
    --all-fast) get_all_fast ;;
    --all-slow) get_all_slow ;;
    *) echo "Unknown: $cmd" ;;
esac
