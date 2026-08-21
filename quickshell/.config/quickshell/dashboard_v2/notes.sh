#!/usr/bin/env bash

NOTES_DIR="$HOME/.config/quickshell/dashboard_v2"
NOTES_FILE="${NOTES_DIR}/notes.txt"

mkdir -p "$NOTES_DIR"

if [ ! -f "$NOTES_FILE" ]; then
    cat <<EOF > "$NOTES_FILE"
Refaktoryzacja quickshell
Napisać widget notatek
Dodać prognozę pogody
EOF
fi

ACTION="$1"

if [ "$ACTION" = "add" ]; then
    TEXT="$2"
    if [ -n "$TEXT" ]; then
        echo "$TEXT" >> "$NOTES_FILE"
    fi
elif [ "$ACTION" = "delete" ]; then
    IDX="$2"
    if [[ "$IDX" =~ ^[0-9]+$ ]]; then
        LINE_NUM=$((IDX + 1))
        sed -i "${LINE_NUM}d" "$NOTES_FILE"
    fi
elif [ "$ACTION" = "clear" ]; then
    > "$NOTES_FILE"
fi

# Zwracanie notatek jako JSON
if command -v jq &>/dev/null; then
    jq -R -s -c 'split("\n") | map(select(length > 0))' "$NOTES_FILE"
else
    # Awaryjny parser bash/sed
    echo -n "["
    first=1
    while IFS= read -r line || [ -n "$line" ]; do
        [ -z "$line" ] && continue
        if [ $first -eq 1 ]; then
            first=0
        else
            echo -n ","
        fi
        escaped=$(echo "$line" | sed 's/"/\\"/g')
        echo -n "\"$escaped\""
    done < "$NOTES_FILE"
    echo "]"
fi
