#!/bin/bash

QUERY="$1"
SEARCH_DIR="${2:-$HOME}"
LIMIT=20

CLEAN_QUERY=$(echo "$QUERY" | xargs)

# --- 0. EMPTY STATE (Recent Files) ---
if [[ -z "$CLEAN_QUERY" ]]; then
    echo "["
    FIRST=true
    # Get 10 most recently modified files in $HOME (excluding hidden dirs)
    while IFS= read -r line; do
        [[ "$FIRST" == false ]] && echo ","
        NAME=$(basename "$line")
        MIME=$(xdg-mime query filetype "$line")
        jq -c -n --arg path "$line" --arg name "Ostatnie: $NAME" --arg mime "$MIME" --arg type "file" \
            '{path: $path, name: $name, mime: $mime, type: $type}'
        FIRST=false
    done < <(fd --type f --hidden --exclude .git --exclude .cache --max-results 10 --changed-within 1day . "$HOME" 2>/dev/null)
    echo "]"
    exit 0
fi

# --- 0.1 Command Palette Modes ---
if [[ "$CLEAN_QUERY" =~ ^([a-z:]+)\ (.*) ]] || [[ "$CLEAN_QUERY" =~ ^(:e)$ ]]; then
    MODE="${BASH_REMATCH[1]}"
    VAL="${BASH_REMATCH[2]}"
    
    case "$MODE" in
        :e)
            echo "["
            FIRST_E=true
            EMOJI_FILE="/usr/share/unicode/emoji/emoji-test.txt"
            
            # Dynamic search through system emoji database
            # 1. Filter fully-qualified emojis
            # 2. Filter by user query ($VAL)
            # 3. Limit to 50 results for speed
            # 4. Parse into ICON|NAME format
            grep "fully-qualified" "$EMOJI_FILE" | grep -v "^#" | grep -i "$VAL" | head -n 50 | \
            sed -E 's/^.*# ([^ ]+) E[0-9.]+ (.*)$/\1|\2/' | \
            while IFS="|" read -r E_ICON E_NAME; do
                [[ "$FIRST_E" == false ]] && echo ","
                jq -c -n --arg name "$E_ICON $E_NAME" --arg path "$E_ICON" --arg type "emoji" --arg icon "$E_ICON" \
                    '{name: $name, path: $path, type: $type, icon: $icon}'
                FIRST_E=false
            done
            echo "]"
            exit 0
            ;;
    esac
fi

# Get Application Paths from XDG
IFS=':' read -ra ADDR <<< "$XDG_DATA_DIRS"
APP_PATHS=()
for i in "${ADDR[@]}"; do
    [[ -d "$i/applications" ]] && APP_PATHS+=("$i/applications")
done
local_apps="$HOME/.local/share/applications"
if [[ -d "$local_apps" ]] && [[ ! " ${APP_PATHS[*]} " =~ " ${local_apps} " ]]; then
    APP_PATHS+=("$local_apps")
fi

# Get Default Browser Info
DEFAULT_BROWSER_HANDLER=$(xdg-settings get default-web-browser 2>/dev/null || xdg-mime query default text/html)
BROWSER_NAME="Internet"
BROWSER_ICON="internet-web-browser"
BROWSER_DESKTOP=""

if [[ -n "$DEFAULT_BROWSER_HANDLER" ]]; then
    for dir in "${APP_PATHS[@]}"; do
        if [[ -f "$dir/$DEFAULT_BROWSER_HANDLER" ]]; then
            BROWSER_DESKTOP="$dir/$DEFAULT_BROWSER_HANDLER"
            break
        elif [[ -f "$dir/${DEFAULT_BROWSER_HANDLER%.desktop}.desktop" ]]; then
            BROWSER_DESKTOP="$dir/${DEFAULT_BROWSER_HANDLER%.desktop}.desktop"
            break
        fi
    done

    if [[ -n "$BROWSER_DESKTOP" ]]; then
        BROWSER_NAME=$(grep -m1 "^Name=" "$BROWSER_DESKTOP" | cut -d'=' -f2-)
        BROWSER_ICON=$(grep -m1 "^Icon=" "$BROWSER_DESKTOP" | cut -d'=' -f2-)
    fi
fi

# Start JSON array
echo "["
FIRST=true

# --- 0.2 Calculator ---
if [[ "$CLEAN_QUERY" =~ ^[0-9+*/().^[:space:][:digit:]-]+$ ]] && [[ "$CLEAN_QUERY" =~ [0-9] ]] && [[ "$CLEAN_QUERY" =~ [+*/^] ]]; then
    CALC_RES=$(python3 -c "import math; print(eval('$CLEAN_QUERY'))" 2>/dev/null)
    if [[ -n "$CALC_RES" ]]; then
        jq -c -n --arg name "Wynik: $CALC_RES" --arg path "$CALC_RES" --arg type "calc" --arg icon "accessories-calculator" \
            '{name: $name, path: $path, type: $type, icon: $icon}'
        FIRST=false
    fi
fi

# --- 1. Applications ---
if [[ ! "$QUERY" =~ (ext:|dir:) ]]; then
    while IFS= read -r line; do
        [[ "$FIRST" == false ]] && echo ","
        NAME=$(grep -m1 "^Name=" "$line" | cut -d'=' -f2-)
        ICON=$(grep -m1 "^Icon=" "$line" | cut -d'=' -f2-)
        [[ -z "$NAME" ]] && NAME=$(basename "$line" .desktop)
        
        jq -c -n --arg path "$line" --arg name "$NAME" --arg icon "$ICON" --arg mime "application/x-desktop" --arg type "app" \
            '{path: $path, name: $name, icon: $icon, mime: $mime, type: $type}'
        FIRST=false
    done < <(fd --ignore-case --fixed-strings --max-results 5 "$CLEAN_QUERY" "${APP_PATHS[@]}" 2>/dev/null)
fi

# --- 2. Files ---
EXT_FILTER=""
DIR_FILTER="$SEARCH_DIR"
if [[ "$QUERY" =~ ext:([a-zA-Z0-9]+) ]]; then EXT_FILTER="${BASH_REMATCH[1]}"; fi
if [[ "$QUERY" =~ dir:([^ ]+) ]]; then 
    DIR_FILTER="${BASH_REMATCH[1]}"
    DIR_FILTER="${DIR_FILTER/#\~/$HOME}"
fi

FD_CMD=("fd" "--fixed-strings" "--ignore-case" "--max-results" "$LIMIT")
[[ -n "$EXT_FILTER" ]] && FD_CMD+=("-e" "$EXT_FILTER")
[[ -n "$CLEAN_QUERY" ]] && FD_CMD+=("$CLEAN_QUERY")
FD_CMD+=("$DIR_FILTER")

while IFS= read -r line; do
    [[ "$line" == *.desktop ]] && continue
    [[ "$FIRST" == false ]] && echo ","
    NAME=$(basename "$line")
    MIME=$(xdg-mime query filetype "$line")
    
    jq -c -n --arg path "$line" --arg name "$NAME" --arg mime "$MIME" --arg type "file" \
        '{path: $path, name: $name, mime: $mime, type: $type}'
    FIRST=false
done < <("${FD_CMD[@]}" 2>/dev/null)

# --- 3. Content ---
if [[ ${#CLEAN_QUERY} -gt 3 && -z "$EXT_FILTER" ]]; then
    RG_CMD=("rg" "--files-with-matches" "--ignore-case" "--fixed-strings" "--max-count" "1" "--max-results" 3 "-g" "!*.pdf" "$CLEAN_QUERY" "$DIR_FILTER")
    while IFS= read -r line; do
        [[ "$FIRST" == false ]] && echo ","
        NAME=$(basename "$line")
        MIME=$(xdg-mime query filetype "$line")
        
        jq -c -n --arg path "$line" --arg name "$NAME" --arg mime "$MIME" --arg type "content" \
            '{path: $path, name: $name, mime: $mime, type: $type}'
    done < <("${RG_CMD[@]}" 2>/dev/null)
fi

# --- 4. Fallback Actions ---
[[ "$FIRST" == false ]] && echo ","
jq -c -n --arg path "$CLEAN_QUERY" --arg name "Szukaj w $BROWSER_NAME: $CLEAN_QUERY" --arg icon "$BROWSER_ICON" --arg mime "text/html" --arg type "web" \
    '{path: $path, name: $name, icon: $icon, mime: $mime, type: $type}'
echo ","
jq -c -n --arg path "$CLEAN_QUERY" --arg name "Uruchom w Kitty: $CLEAN_QUERY" --arg icon "kitty" --arg mime "application/x-executable" --arg type "term" \
    '{path: $path, name: $name, icon: $icon, mime: $mime, type: $type}'

echo "]"
