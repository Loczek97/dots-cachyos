#!/usr/bin/env bash

# Check if WiFi is enabled (use English locale for consistent output)
POWER=$(LC_ALL=C nmcli radio wifi)

if [[ "$POWER" == "disabled" ]]; then
    echo '{ "power": "off", "connected": null, "networks": [] }'
    exit 0
fi

# Function to get icon based on signal strength
get_icon() {
    local signal=$1
    if [[ $signal -ge 80 ]]; then echo "󰤨";
    elif [[ $signal -ge 60 ]]; then echo "󰤥";
    elif [[ $signal -ge 40 ]]; then echo "󰤢";
    elif [[ $signal -ge 20 ]]; then echo "󰤟";
    else echo "󰤯"; fi
}

CACHE_DIR="/tmp/quickshell_network_cache"
mkdir -p "$CACHE_DIR"

# Get current connection details using connection show (faster and more reliable)
CURRENT_CONN=$(LC_ALL=C nmcli -t -f NAME,TYPE connection show --active 2>/dev/null | grep ':802-11-wireless$' | cut -d: -f1 | head -n1)

if [[ -n "$CURRENT_CONN" ]]; then
    ssid="$CURRENT_CONN"
    
    # Get signal strength using iw (more reliable than nmcli dev wifi)
    IFACE=$(LC_ALL=C nmcli -t -f DEVICE,TYPE d | awk -F: '$2=="wifi"{print $1;exit}')
    signal=50  # default
    if [ -n "$IFACE" ]; then
        dbm=$(iw dev "$IFACE" link 2>/dev/null | grep signal | awk '{print $2}')
        if [ -n "$dbm" ]; then
            # Convert dBm to percentage (-30 dBm = 100%, -90 dBm = 0%)
            signal=$(( 100 - ((-30 - dbm) * 100 / 60) ))
            [ $signal -lt 0 ] && signal=0
            [ $signal -gt 100 ] && signal=100
        fi
    fi
    
    icon=$(get_icon "$signal")
    
    # Get security from connection and convert to friendly name
    security_raw=$(LC_ALL=C nmcli -t -f 802-11-wireless-security.key-mgmt connection show "$CURRENT_CONN" 2>/dev/null | head -n1)
    if [ -z "$security_raw" ] || [ "$security_raw" == "--" ]; then
        security="None"
    elif [[ "$security_raw" == *"sae"* ]]; then
        security="WPA3"
    elif [[ "$security_raw" == *"wpa-psk"* ]] || [[ "$security_raw" == *"wpa-eap"* ]]; then
        security="WPA2"
    else
        security="WPA"
    fi
    
    # Safe filename for cache
    SAFE_SSID="${ssid//[^a-zA-Z0-9]/_}"
    CACHE_FILE="$CACHE_DIR/wifi_$SAFE_SSID"
    
    # Load cached IP and FREQ if they exist to prevent blocking
    if [ -f "$CACHE_FILE" ]; then
        source "$CACHE_FILE"
    fi
    
    # If cache is missing, fetch the expensive stats once and save them
    if [ -z "$IP" ] || [ "$IP" == "No IP" ] || [ -z "$FREQ" ]; then
        IP=$(ip -4 addr show dev "$IFACE" 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n1)
        [ -z "$IP" ] && IP="No IP"
        
        FREQ=$(iw dev "$IFACE" link 2>/dev/null | grep freq | awk '{print $2}')
        [ -n "$FREQ" ] && FREQ="${FREQ} MHz" || FREQ="Unknown"
        
        echo "IP=\"$IP\"" > "$CACHE_FILE"
        echo "FREQ=\"$FREQ\"" >> "$CACHE_FILE"
    fi

    CONNECTED_JSON=$(jq -n \
                  --arg id "$ssid" \
                  --arg ssid "$ssid" \
                  --arg icon "$icon" \
                  --arg signal "$signal" \
                  --arg security "$security" \
                  --arg ip "$IP" \
                  --arg freq "$FREQ" \
                  '{id: $id, ssid: $ssid, icon: $icon, signal: $signal, security: $security, ip: $ip, freq: $freq}')
else
    CONNECTED_JSON="null"
fi

# Get available networks INSTANTLY using --rescan no with English locale
NETWORKS_JSON=$(LC_ALL=C timeout 1 nmcli -t -f active,ssid,signal,security device wifi list --rescan no 2>/dev/null | \
    awk -F: '!seen[$2]++ && $2 != "" {print $2":"$3":"$4}' | \
    head -n 24 | \
    while IFS=':' read -r ssid signal security; do
        icon=$(get_icon "$signal")
        jq -n \
           --arg id "$ssid" \
           --arg ssid "$ssid" \
           --arg icon "$icon" \
           --arg signal "$signal" \
           --arg security "$security" \
           '{id: $id, ssid: $ssid, icon: $icon, signal: $signal, security: $security}'
    done | jq -s '.')

echo $(jq -n \
       --arg power "on" \
       --argjson connected "${CONNECTED_JSON:-null}" \
       --argjson networks "${NETWORKS_JSON:-[]}" \
       '{power: $power, connected: $connected, networks: $networks}')
