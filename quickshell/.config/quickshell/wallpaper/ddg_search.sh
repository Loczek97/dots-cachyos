#!/usr/bin/env bash

QUERY="$1"
SESSION_ID="$2"
LOG_FILE="/tmp/qs_wall_search.log"

echo "[BASH $(date +%H:%M:%S)] Pipeline started for: $QUERY (Session: $SESSION_ID)" >> "$LOG_FILE"

# Bezpieczne zabijanie poprzedników
for p in $(pgrep -f 'ddg_search.sh\|get_ddg_links.py'); do
    if [ "$p" != "$$" ] && [ "$p" != "$PPID" ]; then
        kill -9 "$p" 2>/dev/null || true
    fi
done

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
CACHE_ROOT="$HOME/.cache/wallpaper_picker"
SESSION_DIR="$CACHE_ROOT/search_thumbs/$SESSION_ID"
MARKER_DIR="$CACHE_ROOT/colors_markers"
MAP_FILE="$CACHE_ROOT/search_map.txt"
CONTROL_FILE="/tmp/ddg_search_control"

mkdir -p "$SESSION_DIR"
mkdir -p "$MARKER_DIR"
echo "run" > "$CONTROL_FILE"
echo -n "" > "$MAP_FILE" 

python3 -u "$SCRIPT_DIR/get_ddg_links.py" "$QUERY" 2>> "$LOG_FILE" | while IFS='|' read -r thumb_url full_url; do
    state=$(cat "$CONTROL_FILE" 2>/dev/null | tr -d '[:space:]')
    if [[ "$state" == "stop" ]]; then exit 0; fi

    if [ -z "$thumb_url" ] || [ -z "$full_url" ]; then continue; fi

    uuid=$(date +%s%N)
    filename="wall_${uuid}.jpg"
    filepath="$SESSION_DIR/$filename"

    if curl -s -L -m 5 --retry 1 -A "Mozilla/5.0" "$thumb_url" -o "$filepath"; then
        if [ -s "$filepath" ]; then
            echo "$filename|$full_url" >> "$MAP_FILE"
            
            # EKSTRAKCJA KOLORU (dla sortowania i filtrów)
            hex=$(magick "$filepath" -scale 1x1\! -alpha off -format "%[hex]" info: | tail -c 7)
            if [ -n "$hex" ]; then
                touch "$MARKER_DIR/${filename}_HEX_${hex}"
            fi
            
            echo "[BASH] Downloaded & Colored: $filename (#$hex)" >> "$LOG_FILE"
        else
            rm -f "$filepath"
        fi
    fi
done
