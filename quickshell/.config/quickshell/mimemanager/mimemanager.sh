#!/usr/bin/env bash

MIME_LIST="$HOME/.config/mimeapps.list"

backup_mimeapps() {
    if [ ! -f "$MIME_LIST.bak" ] && [ -f "$MIME_LIST" ]; then
        cp "$MIME_LIST" "$MIME_LIST.bak"
    fi
}

list_mimes() {
    {
        if [ -f "$MIME_LIST" ]; then
            grep "=" "$MIME_LIST" | grep -v "\[" | cut -d= -f1
        fi
        echo "text/plain"; echo "text/html"; echo "image/jpeg"; echo "image/png"
        echo "video/mp4"; echo "application/pdf"; echo "inode/directory"
    } | sort -u | while read -r mime; do
        [ -z "$mime" ] && continue
        default=$(xdg-mime query default "$mime")
        echo "{\"mime\": \"$mime\", \"default\": \"$default\"}"
    done | jq -s '.'
}

list_apps() {
    local mime=$1
    if [ -z "$mime" ]; then echo "[]"; return; fi
    
    find /usr/share/applications /usr/local/share/applications "$HOME/.local/share/applications" -name "*.desktop" 2>/dev/null | while read -r path; do
        app=$(basename "$path")
        name=$(grep -m1 "^Name=" "$path" | cut -d= -f2-)
        icon=$(grep -m1 "^Icon=" "$path" | cut -d= -f2-)
        
        jq -c -n --arg id "$app" --arg name "${name:-$app}" --arg icon "$icon" '{id: $id, name: $name, icon: $icon}'
    done | sort -u | jq -s '.'
}

set_default() {
    local mime=$1; local app=$2
    if [ -z "$mime" ] || [ -z "$app" ]; then return 1; fi
    backup_mimeapps
    xdg-mime default "$app" "$mime"
    echo "{\"status\": \"success\"}"
}

reset_default() {
    local mime=$1; if [ -z "$mime" ]; then return 1; fi
    backup_mimeapps
    [ -f "$MIME_LIST" ] && sed -i "/^$mime=/d" "$MIME_LIST"
    echo "{\"status\": \"reset\"}"
}

case "$1" in
    list_mimes) list_mimes ;;
    list_apps)  list_apps "$2" ;;
    set)        set_default "$2" "$3" ;;
    reset)      reset_default "$2" ;;
    *)          exit 1 ;;
esac
