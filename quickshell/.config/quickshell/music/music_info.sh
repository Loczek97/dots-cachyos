#!/usr/bin/env bash

TMP_DIR="/tmp/eww_covers"
mkdir -p "$TMP_DIR"
PLACEHOLDER="$TMP_DIR/placeholder_blank.png"

# --- 1. ENSURE PLACEHOLDER EXISTS ---
if [ ! -f "$PLACEHOLDER" ]; then
    convert -size 500x500 xc:"#313244" "$PLACEHOLDER"
fi

# --- 2. GET ALL MPRIS DATA IN ONE CALL ---
metadata=$(playerctl metadata --format '{{status}}
{{mpris:artUrl}}
{{xesam:title}}
{{xesam:artist}}
{{playerName}}
{{mpris:length}}
{{position}}' 2>/dev/null)

if [ -n "$metadata" ]; then
    # Parse lines
    {
        read -r STATUS
        read -r rawUrl
        read -r title
        read -r artist
        read -r player_raw
        read -r len_micro
        read -r pos_micro
    } <<EOF
$metadata
EOF

    if [ "$STATUS" = "Playing" ] || [ "$STATUS" = "Paused" ]; then
        # Generate Hash
        idStr="${title:-unknown}-${artist:-unknown}"
        trackHash=$(echo -n "$idStr" | md5sum | cut -d" " -f1)
        
        finalArt="$TMP_DIR/${trackHash}_art.jpg"
        blurPath="$TMP_DIR/${trackHash}_blur.png"
        colorPath="$TMP_DIR/${trackHash}_grad.txt"
        textPath="$TMP_DIR/${trackHash}_text.txt"
        lockFile="$TMP_DIR/${trackHash}.lock"

        # Default display values (Placeholder)
        displayArt="$PLACEHOLDER"
        displayBlur="$PLACEHOLDER"
        displayGrad="linear-gradient(45deg, #cba6f7, #89b4fa, #f38ba8, #cba6f7)"
        displayText="#cdd6f4"

        # --- 3. ASYNC BACKGROUND LOGIC ---
        if [ -f "$finalArt" ] && [ -s "$finalArt" ]; then
            # Cache Hit: Use the real files
            displayArt="$finalArt"
            # Only use blur/colors if they are ready too
            if [ -f "$blurPath" ]; then displayBlur="$blurPath"; fi
            if [ -f "$colorPath" ]; then displayGrad=$(cat "$colorPath" 2>/dev/null || echo "$displayGrad"); fi
            if [ -f "$textPath" ]; then displayText=$(cat "$textPath" 2>/dev/null || echo "$displayText"); fi
        else
            # Cache Miss: Trigger Background Download
            if [ ! -f "$lockFile" ] && [ -n "$rawUrl" ]; then
                touch "$lockFile"
                (
                    # A. Download/Copy Source
                    if [[ "$rawUrl" == http* ]]; then
                        curl -s -L --max-time 10 -o "$finalArt" "$rawUrl"
                    else
                        cleanPath="${rawUrl#file://}"
                        if [ -f "$cleanPath" ]; then
                            cp "$cleanPath" "$finalArt"
                        else
                            cp "$PLACEHOLDER" "$finalArt"
                        fi
                    fi

                    # B. Validate Download
                    if [ ! -s "$finalArt" ]; then
                        cp "$PLACEHOLDER" "$finalArt"
                    fi

                    # C. Generate Effects (Blur & Colors)
                    isPlaceholder=$(convert "$finalArt" -format "%[hex:u.p{0,0}]" info:)
                    
                    if [[ "$isPlaceholder" == "313244" ]]; then
                        cp "$finalArt" "$blurPath"
                    else
                        convert "$finalArt" -blur 0x20 -brightness-contrast -30x-10 "$blurPath"
                        
                        colors=$(convert "$finalArt" -resize 100x100 -quantize RGB -colors 3 -depth 8 -format "%c" histogram:info: | \
                                 sed -n 's/.*#\([0-9A-Fa-f]\{6\}\).*/#\1/p' | tr '\n' ' ')
                        read -r -a color_array <<< "$colors"
                        c1=${color_array[0]:-#cba6f7}
                        c2=${color_array[1]:-$c1}
                        c3=${color_array[2]:-$c1}
                        
                        echo "linear-gradient(45deg, $c1, $c2, $c3, $c1)" > "$colorPath"
                        opp_raw=$(convert xc:"$c1" -negate -depth 8 -format "%[hex:u]" info: | tr -d '\n')
                        echo "#$opp_raw" > "$textPath"
                    fi

                    # D. Cleanup
                    rm "$lockFile"
                    # Housekeeping: keep only recent 20 files
                    (cd "$TMP_DIR" && ls -1t | tail -n +21 | xargs -r rm 2>/dev/null)
                ) &
            fi
        fi

        # --- 4. TIMING & DEVICE INFO ---
        if [ -z "$len_micro" ] || [ "$len_micro" -eq 0 ]; then len_micro=1000000; fi
        len_sec=$((len_micro / 1000000))
        pos_sec=$((pos_micro / 1000000))
        percent=$((pos_sec * 100 / len_sec))
        pos_str=$(printf "%02d:%02d" $((pos_sec/60)) $((pos_sec%60)))
        len_str=$(printf "%02d:%02d" $((len_sec/60)) $((len_sec%60)))
        time_str="${pos_str} / ${len_str}"

        player_nice="${player_raw^}"

        # Audio Device
        sink_name=$(pactl get-default-sink 2>/dev/null)
        dev_icon="󰓃"; dev_name="Speaker"
        if [[ "$sink_name" == *"bluez"* ]]; then
            dev_icon="󰂯"
            local sinks_info=$(pactl list sinks 2>/dev/null)
            local found=0
            local readable_name=""
            while IFS= read -r line; do
                if [[ "$line" =~ Name:[[:space:]]*(.*) ]]; then
                    if [[ "${BASH_REMATCH[1]}" == "$sink_name" ]]; then
                        found=1
                    else
                        found=0
                    fi
                elif [[ $found -eq 1 && "$line" =~ Description:[[:space:]]*(.*) ]]; then
                    readable_name="${BASH_REMATCH[1]}"
                    break
                fi
            done <<< "$sinks_info"
            readable_name=$(echo "$readable_name" | xargs)
            if [ -n "$readable_name" ]; then dev_name="$readable_name"; else dev_name="Głośnik"; fi
        elif [[ "$sink_name" == *"usb"* ]]; then
            dev_icon="󰓃"; dev_name="USB Audio"
        elif [[ "$sink_name" == *"pci"* ]]; then
            dev_icon="󰓃"; dev_name="System"
        fi

        # --- 5. JSON OUTPUT ---
        jq -n -c \
            --arg title "$title" \
            --arg artist "$artist" \
            --arg status "$STATUS" \
            --arg len "$len_sec" \
            --arg pos "$pos_sec" \
            --arg len_str "$len_str" \
            --arg pos_str "$pos_str" \
            --arg time_str "$time_str" \
            --arg percent "$percent" \
            --arg source "$player_nice" \
            --arg pname "$player_raw" \
            --arg blur "$displayBlur" \
            --arg grad "$displayGrad" \
            --arg txtColor "$displayText" \
            --arg devIcon "$dev_icon" \
            --arg devName "$dev_name" \
            --arg finalArt "$displayArt" \
            '{
                title: $title,
                artist: $artist,
                status: $status,
                length: $len, 
                position: $pos, 
                lengthStr: $len_str, 
                positionStr: $pos_str, 
                timeStr: $time_str,
                percent: $percent,
                source: $source,
                playerName: $pname,
                blur: $blur,
                grad: $grad,
                textColor: $txtColor,
                deviceIcon: $devIcon,
                deviceName: $devName,
                artUrl: $finalArt
            }'
        exit 0
    fi
fi

# Fallback (Stopped state)
jq -n -c \
--arg placeholder "$PLACEHOLDER" \
'{
    title: "Brak",
    artist: "Brak",
    status: "Zatrzymano",
    percent: 0,
    lengthStr: "00:00",
    positionStr: "00:00",
    timeStr: "--:-- / --:--",
    source: "Offline",
    playerName: "",
    blur: $placeholder,
    grad: "linear-gradient(45deg, #cba6f7, #89b4fa, #f38ba8, #cba6f7)",
    textColor: "#cdd6f4",
    deviceIcon: "󰓃",
    deviceName: "Głośnik",
    artUrl: $placeholder
}'
