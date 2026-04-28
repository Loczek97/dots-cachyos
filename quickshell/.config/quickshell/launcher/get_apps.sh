#!/usr/bin/env bash

# get_apps.sh - Reliable app lister using jq for safe JSON construction
search_dirs=(
    "$HOME/.local/share/applications"
    "/usr/share/applications"
    "/usr/local/share/applications"
)

tmp_file=$(mktemp)

for s_dir in "${search_dirs[@]}"; do
    [ -d "$s_dir" ] || continue
    
    find "$s_dir" -name "*.desktop" | while read -r path; do
        entry_content=$(sed -n '/^\[Desktop Entry\]/,/^\[/p' "$path")
        
        if echo "$entry_content" | grep -q "^NoDisplay=true"; then
            continue
        fi
        
        name=$(echo "$entry_content" | grep "^Name=" | head -n1 | cut -d= -f2-)
        exec_cmd=$(echo "$entry_content" | grep "^Exec=" | head -n1 | cut -d= -f2-)
        icon=$(echo "$entry_content" | grep "^Icon=" | head -n1 | cut -d= -f2-)
        
        [ -z "$name" ] || [ -z "$exec_cmd" ] && continue
        
        # Clean command
        exec_cmd=$(echo "$exec_cmd" | sed 's/%[fFuUnNdDeEiIkKmM]//g' | sed 's/^[ \t]*//;s/[ \t]*$//' | sed 's/"//g')
        [ -z "$icon" ] && icon="application-x-executable"
        
        echo "$name|$exec_cmd|$icon" >> "$tmp_file"
    done
done

# Use jq to build a proper JSON array
sort -u "$tmp_file" | while IFS="|" read -r name exec_cmd icon; do
    jq -n --arg n "$name" --arg e "$exec_cmd" --arg i "$icon" '{name: $n, exec: $e, icon: $i}'
done | jq -s '.'

rm -f "$tmp_file"
