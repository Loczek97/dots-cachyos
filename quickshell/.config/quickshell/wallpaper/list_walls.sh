#!/bin/bash
# wallpaper/list_walls.sh
LOG="/tmp/qs_list_walls.log"
echo "--- Start: $(date) ---" > "$LOG"

THUMBS="$HOME/.cache/wallpaper_picker/thumbs"
MARKERS="$HOME/.cache/wallpaper_picker/colors_markers"
SORTED="$HOME/.cache/wallpaper_picker/sorted_thumbs"

mkdir -p "$MARKERS" "$SORTED"
find "$SORTED" -type l -delete

if command -v magick &>/dev/null; then MAGICK="magick"; else MAGICK="convert"; fi

# Funkcja konwertująca HEX na HUE (0-360) za pomocą awk
get_hue_awk() {
    echo "$1" | awk '{
        hex = toupper($1);
        if (sub(/^#/, "", hex));
        r = strtonum("0x" substr(hex, 1, 2)) / 255;
        g = strtonum("0x" substr(hex, 3, 2)) / 255;
        b = strtonum("0x" substr(hex, 5, 2)) / 255;
        
        max = r; if (g > max) max = g; if (b > max) max = b;
        min = r; if (g < min) min = g; if (b < min) min = b;
        d = max - min;
        
        if (d == 0) { print 998; exit; }
        if (max == r) h = (g - b) / d;
        else if (max == g) h = (b - r) / d + 2;
        else h = (r - g) / d + 4;
        h *= 60;
        if (h < 0) h += 360;
        print int(h);
    }'
}

for file in "$THUMBS"/*; do
    [ -f "$file" ] || continue
    fname=$(basename "$file")
    
    # 1. Pobierz kolor (z cache lub nową ekstrakcją)
    marker=$(ls "$MARKERS/${fname}_HEX_"* 2>/dev/null | head -n 1)
    if [ -z "$marker" ]; then
        hex=$($MAGICK "$file" -scale 1x1\! -alpha off -format "%[hex]" info: 2>/dev/null | grep -oE '[0-9A-Fa-f]{6}' | head -n 1)
        if [ -n "$hex" ]; then
            touch "$MARKERS/${fname}_HEX_${hex}"
            hex_val="$hex"
        else
            hex_val=""
        fi
    else
        hex_val="${marker##*_HEX_}"
    fi
    
    # 2. Wylicz Hue
    hue="999"
    if [ -n "$hex_val" ]; then
        hue=$(get_hue_awk "$hex_val")
    fi
    
    # 3. Zapisz w logach dla debugowania
    echo "File: $fname | Hex: $hex_val | Hue: $hue" >> "$LOG"
    
    # 4. Stwórz symlink
    hue_padded=$(printf "%03d" "$hue")
    ln -s "$file" "$SORTED/${hue_padded}_${fname}" 2>/dev/null
done

echo "--- Finish ---" >> "$LOG"
