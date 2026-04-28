#!/usr/bin/env bash

# mimemanager.sh - Backend for Quickshell MimeManager widget
# Handles CRUD operations for mimetypes and default applications

MIME_LIST="$HOME/.config/mimeapps.list"

# Backup before first destructive change
backup_mimeapps() {
    if [ ! -f "$MIME_LIST.bak" ] && [ -f "$MIME_LIST" ]; then
        cp "$MIME_LIST" "$MIME_LIST.bak"
    fi
}

list_mimes() {
    # Get a list of mimetypes that have user-defined defaults
    # or are commonly used.
    
    # We'll start with those in [Default Applications] of mimeapps.list
    # and combine with some common ones.
    
    {
        if [ -f "$MIME_LIST" ]; then
            grep "=" "$MIME_LIST" | grep -v "\[" | cut -d= -f1
        fi
        # Add some common ones just in case they aren't in the list yet
        echo "text/plain"
        echo "text/html"
        echo "image/jpeg"
        echo "image/png"
        echo "video/mp4"
        echo "video/x-matroska"
        echo "application/pdf"
        echo "inode/directory"
    } | sort -u | while read -r mime; do
        [ -z "$mime" ] && continue
        default=$(xdg-mime query default "$mime")
        echo "{\"mime\": \"$mime\", \"default\": \"$default\"}"
    done | jq -s '.'
}

list_apps() {
    local mime=$1
    if [ -z "$mime" ]; then echo "[]"; return; fi
    
    # Use gio to find recommended/registered apps
    gio mime "$mime" | grep ".desktop" | sed 's/^[ \t]*//' | cut -d' ' -f1 | sort -u | while read -r app; do
        [ -z "$app" ] && continue
        # Try to get the pretty name from the desktop file
        name=""
        for dir in "$HOME/.local/share/applications" "/usr/share/applications" "/usr/local/share/applications"; do
            if [ -f "$dir/$app" ]; then
                name=$(grep "^Name=" "$dir/$app" | head -n1 | cut -d= -f2)
                break
            fi
        done
        [ -z "$name" ] && name="$app"
        echo "{\"id\": \"$app\", \"name\": \"$name\"}"
    done | jq -s '.'
}

set_default() {
    local mime=$1
    local app=$2
    if [ -z "$mime" ] || [ -z "$app" ]; then return 1; fi
    
    backup_mimeapps
    xdg-mime default "$app" "$mime"
    echo "{\"status\": \"success\", \"mime\": \"$mime\", \"app\": \"$app\"}"
}

reset_default() {
    local mime=$1
    if [ -z "$mime" ]; then return 1; fi
    
    backup_mimeapps
    # xdg-mime doesn't have a direct 'reset', so we remove from [Default Applications]
    if [ -f "$MIME_LIST" ]; then
        # This is a bit naive but works for standard mimeapps.list
        sed -i "/^$mime=/d" "$MIME_LIST"
    fi
    echo "{\"status\": \"reset\", \"mime\": \"$mime\"}"
}

case "$1" in
    list_mimes) list_mimes ;;
    list_apps)  list_apps "$2" ;;
    set)        set_default "$2" "$3" ;;
    reset)      reset_default "$2" ;;
    *)          echo "Usage: $0 {list_mimes|list_apps <mime>|set <mime> <app>|reset <mime>}" ;;
esac
