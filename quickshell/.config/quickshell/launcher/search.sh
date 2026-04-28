#!/bin/bash

QUERY="$1"
SEARCH_DIR="${2:-$HOME}"
LIMIT=20

if [[ -z "$QUERY" ]]; then
    exit 0
fi

CLEAN_QUERY=$(echo "$QUERY" | xargs)

# Get Default Browser Info
DEFAULT_BROWSER_HANDLER=$(xdg-settings get default-web-browser 2>/dev/null || xdg-mime query default text/html)
BROWSER_NAME="Internet"
BROWSER_ICON="internet-web-browser"
BROWSER_DESKTOP=""

if [[ -n "$DEFAULT_BROWSER_HANDLER" ]]; then
    for dir in "/usr/share/applications" "$HOME/.local/share/applications" "/usr/local/share/applications"; do
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

# --- 1. Applications ---
if [[ ! "$QUERY" =~ (ext:|dir:) ]]; then
    APP_PATHS=("/usr/share/applications" "$HOME/.local/share/applications")
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
