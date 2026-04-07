#!/usr/bin/env bash
export LC_NUMERIC=C

CAL_SCRIPT="$HOME/.config/quickshell/calendar/weather.sh"
cache_dir="$HOME/.cache/eww/weather"
json_file="${cache_dir}/weather.json"

mkdir -p "${cache_dir}"

ensure_data() {
    if [ -x "$CAL_SCRIPT" ]; then
        "$CAL_SCRIPT" --json >/dev/null 2>&1 || true
    fi
}

case "$1" in
    --getdata)
        if [ -x "$CAL_SCRIPT" ]; then
            "$CAL_SCRIPT" --getdata
        fi
        ;;
    --icon)
        ensure_data
        if [ -f "$json_file" ]; then
            jq -r '.forecast[0].icon' "$json_file" 2>/dev/null || echo ""
        else
            echo ""
        fi
        ;;
    --temp)
        ensure_data
        if [ -f "$json_file" ]; then
            temp=$(jq -r '.forecast[0].max' "$json_file" 2>/dev/null)
            if [ -n "$temp" ] && [ "$temp" != "null" ]; then
                echo "${temp}°C"
            else
                echo ""
            fi
        else
            echo ""
        fi
        ;;
    --hex)
        ensure_data
        if [ -f "$json_file" ]; then
            jq -r '.forecast[0].hex' "$json_file" 2>/dev/null || echo "#cdd6f4"
        else
            echo "#cdd6f4"
        fi
        ;;
esac
