#!/usr/bin/env bash

# Paths
QS_DIR="$HOME/.config/hypr/scripts/quickshell"
BT_PID_FILE="$HOME/.cache/bt_scan_pid"
BT_SCAN_LOG="$HOME/.cache/bt_scan.log"
SRC_DIR="$HOME/.config/backgrounds"
THUMB_DIR="$HOME/.cache/wallpaper_picker/thumbs"
TASKVIEW_ICON_CACHE="$QS_DIR/taskView/DesktopIconCache.js"
TASKVIEW_APPSEARCH_QML="$QS_DIR/taskView/AppSearch.qml"

ACTION="$1"
TARGET="$2"

# -----------------------------------------------------------------------------
# FUNCTION: Map friendly names to QML paths and window focus titles
# -----------------------------------------------------------------------------
get_qml_info() {
    case "$1" in
        battery)   QML_FILE="battery/BatteryPopup.qml";      FOCUS="title:battery-popup" ;;
        calendar)  QML_FILE="calendar/CalendarPopup.qml";    FOCUS="title:calendar_win" ;;
        music)     QML_FILE="music/MusicPopup.qml";          FOCUS="title:music_win" ;;
        network)   QML_FILE="network/NetworkPopup.qml";      FOCUS="title:network-popup" ;;
        stewart)     QML_FILE="stewart/stewart.qml";           FOCUS="title:stewart" ;;
        taskview)  QML_FILE="taskView/WaffleTaskView.qml";  FOCUS="title:quickshell:wTaskView" ;;
        wallpaper) QML_FILE="wallpaper/WallpaperPicker.qml"; FOCUS="title:wallpaper-picker" ;;
        *) 
            echo "Error: Unknown window '$1'."
            echo "Available: battery, calendar, music, network, stewart, taskview, wallpaper"
            exit 1 
            ;;
    esac
}

# -----------------------------------------------------------------------------
# FUNCTION: Clean up all Quickshell popups and background tasks
# -----------------------------------------------------------------------------
cleanup_all() {
    # Kill all known quickshell popups managed by this script
    timeout 2 pkill -f "quickshell.*(BatteryPopup|CalendarPopup|MusicPopup|NetworkPopup|stewart|WallpaperPicker|WaffleTaskView)\.qml" 2>/dev/null || true

    # Cleanup Bluetooth scanning safely
    if [ -f "$BT_PID_FILE" ]; then
        kill $(cat "$BT_PID_FILE") 2>/dev/null
        rm -f "$BT_PID_FILE"
    fi
    
    # Stop bluetooth scan via D-Bus instead of bluetoothctl (non-blocking)
    (timeout 0.5 sh -c 'echo "scan off" | bluetoothctl' &>/dev/null &)
}

# -----------------------------------------------------------------------------
# FUNCTION: Prep Wallpaper Picker (Thumbnails & Active Index)
# -----------------------------------------------------------------------------
handle_wallpaper_prep() {
    mkdir -p "$THUMB_DIR"

    # Generuj brakujące thumbnails SYNCHRONICZNIE
    for img in "$SRC_DIR"/*.{jpg,jpeg,png,webp,gif}; do
        [ -e "$img" ] || continue
        filename=$(basename "$img")
        thumb="$THUMB_DIR/$filename"
        if [ ! -f "$thumb" ]; then
            magick "$img" -resize x420 -quality 70 "$thumb"
        fi
    done

    for vid in "$SRC_DIR"/*.{mp4,mkv,mov,webm}; do
        [ -e "$vid" ] || continue
        filename=$(basename "$vid")
        thumb="$THUMB_DIR/000_$filename"
        if [ ! -f "$thumb" ]; then
            ffmpeg -y -ss 00:00:05 -i "$vid" -vframes 1 -f image2 -q:v 2 "${thumb%.*}.jpg" > /dev/null 2>&1
        fi
    done

    # Usuń stare thumbnails w tle
    (
        for thumb in "$THUMB_DIR"/*; do
            [ -e "$thumb" ] || continue
            filename=$(basename "$thumb")
            clean_name="${filename#000_}"
            if [ ! -f "$SRC_DIR/$clean_name" ]; then
                rm -f "$thumb"
            fi
        done
    ) &

    # Detect Active Wallpaper & Calculate Index
    TARGET_INDEX=0
    CURRENT_SRC=""

    if pgrep -a "mpvpaper" > /dev/null; then
        CURRENT_SRC=$(pgrep -a mpvpaper | grep -o "$SRC_DIR/[^' ]*" | head -n1)
        CURRENT_SRC=$(basename "$CURRENT_SRC")
    fi

    if [ -z "$CURRENT_SRC" ] && command -v awww >/dev/null; then
        CURRENT_SRC=$(awww query 2>/dev/null | grep -o "$SRC_DIR/[^ ]*" | head -n1)
        CURRENT_SRC=$(basename "$CURRENT_SRC")
    fi

    if [ -n "$CURRENT_SRC" ]; then
        EXT="${CURRENT_SRC##*.}"
        if [[ "${EXT,,}" =~ ^(mp4|mkv|mov|webm)$ ]]; then
            TARGET_THUMB="000_$CURRENT_SRC"
        else
            TARGET_THUMB="$CURRENT_SRC"
        fi

        MATCH_LINE=$(ls -1 "$THUMB_DIR" | grep -nF "$TARGET_THUMB" | cut -d: -f1)
        if [ -n "$MATCH_LINE" ]; then
            TARGET_INDEX=$((MATCH_LINE - 1))
        fi
    fi

    export WALLPAPER_INDEX="$TARGET_INDEX"
}

# -----------------------------------------------------------------------------
# FUNCTION: Prep Network (Bluetooth & WiFi scan)
# -----------------------------------------------------------------------------
handle_network_prep() {
    echo "" > "$BT_SCAN_LOG"
    { echo "scan on"; sleep infinity; } | stdbuf -oL bluetoothctl > "$BT_SCAN_LOG" 2>&1 &
    echo $! > "$BT_PID_FILE"
    (nmcli device wifi rescan) &
}

generate_taskview_icon_cache() {
    mkdir -p "$(dirname "$TASKVIEW_ICON_CACHE")"

    local tmp_file
    tmp_file=$(mktemp)

    {
        for dir in \
            /usr/share/applications \
            /usr/local/share/applications \
            "$HOME/.local/share/applications" \
            /var/lib/flatpak/exports/share/applications \
            "$HOME/.local/share/flatpak/exports/share/applications" \
            /var/lib/snapd/desktop/applications
        do
            [[ -d "$dir" ]] || continue

            for file in "$dir"/*.desktop; do
                [[ -f "$file" ]] || continue

                wmclass=$(sed -n 's/^StartupWMClass=//p' "$file" | head -n1)
                icon=$(sed -n 's/^Icon=//p' "$file" | head -n1)
                icon_path=$(sed -n 's/^X-Icon-Path=//p' "$file" | head -n1)
                desktop_base=$(basename "$file" .desktop)
                exec_base=$(sed -n 's/^Exec=//p' "$file" | head -n1 | sed 's/ .*//' | tr -d '"' | xargs -r basename 2>/dev/null)
                app_name=$(sed -n 's/^Name=//p' "$file" | head -n1)
                keywords=$(sed -n 's/^Keywords=//p' "$file" | head -n1)

                printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
                    "$wmclass" "$icon_path" "$icon" "$desktop_base" "$exec_base" "$app_name" "$keywords"
            done
        done
    } | jq -Rn '
        def norm:
            ascii_downcase
            | gsub("\\.desktop$"; "")
            | gsub("^\"|\"$"; "")
            | gsub("%.*$"; "")
            | gsub("[/\\\\]"; "-")
            | gsub("[[:space:]_]"; "-")
            | gsub("[^a-z0-9.+-]"; "-")
            | gsub("-+"; "-")
            | gsub("^-|-$"; "");
        def aliases($value):
            ($value | norm) as $n
            | if $n == "" then [] else
                [$n]
                + (if ($n | endswith("-url-handler")) then [($n | sub("-url-handler$"; ""))] else [] end)
                + (if ($n | startswith("jetbrains-")) then [($n | sub("^jetbrains-"; ""))] else [] end)
                + (if ($n | contains(".")) then [($n | split(".") | last), ($n | split(".") | join("-")), ($n | split(".") | join(""))] else [] end)
                + ($n | split("-") | map(select(length > 2)))
                | unique
              end;
        def resolved_icon($iconPath; $iconName):
            if ($iconPath | startswith("/")) then "file://" + $iconPath
            else ($iconName | norm) end;
        def exec_aliases($execBase; $desktopBase):
            ($execBase | norm) as $exec
            | ($desktopBase | norm) as $desktop
            | if $exec == "" then []
              elif $exec == "steam" and $desktop != "steam" then []
              else aliases($execBase)
              end;
        def exact_aliases($wmclass; $desktopBase; $execBase; $appName):
            (aliases($wmclass) + aliases($desktopBase) + exec_aliases($execBase; $desktopBase) + aliases($appName) | map(select(length > 0)) | unique);
        def keyword_aliases($keywords):
            [($keywords | split(";")[] | norm)] | map(select(length > 0)) | unique;
        reduce (inputs | select(length > 0) | split("\t")) as $parts
            ({};
                if ($parts | length) < 7 then . else
                    ($parts[0] // "") as $wmclass
                    | ($parts[1] // "") as $iconPath
                    | ($parts[2] // "") as $iconName
                    | ($parts[3] // "") as $desktopBase
                    | ($parts[4] // "") as $execBase
                    | ($parts[5] // "") as $appName
                    | ($parts[6] // "") as $keywords
                    | resolved_icon($iconPath; $iconName) as $icon
                    | if $icon == "" then . else
                        reduce (exact_aliases($wmclass; $desktopBase; $execBase; $appName)[]) as $alias
                            (.;
                                . + {($alias): $icon})
                        | reduce (keyword_aliases($keywords)[]) as $alias
                            (.;
                                if has($alias) then . else . + {($alias): $icon} end)
                      end
                end)
    ' > "$tmp_file"

    printf 'var desktopIcons = ' > "$TASKVIEW_ICON_CACHE"
    cat "$tmp_file" >> "$TASKVIEW_ICON_CACHE"
    printf ';\n' >> "$TASKVIEW_ICON_CACHE"

    rm -f "$tmp_file"
}

taskview_icon_cache_is_stale() {
    [[ ! -s "$TASKVIEW_ICON_CACHE" ]] && return 0
    [[ "$TASKVIEW_APPSEARCH_QML" -nt "$TASKVIEW_ICON_CACHE" ]] && return 0

    for dir in \
        /usr/share/applications \
        /usr/local/share/applications \
        "$HOME/.local/share/applications" \
        /var/lib/flatpak/exports/share/applications \
        "$HOME/.local/share/flatpak/exports/share/applications" \
        /var/lib/snapd/desktop/applications
    do
        [[ -d "$dir" ]] || continue
        if find "$dir" -maxdepth 1 -name '*.desktop' -newer "$TASKVIEW_ICON_CACHE" -print -quit 2>/dev/null | grep -q .; then
            return 0
        fi
    done

    return 1
}

ensure_taskview_icon_cache() {
    if [[ ! -s "$TASKVIEW_ICON_CACHE" ]]; then
        generate_taskview_icon_cache
        return
    fi

    if ! taskview_icon_cache_is_stale; then
        return
    fi

    (
        local lock_dir="${TASKVIEW_ICON_CACHE}.lock"
        if mkdir "$lock_dir" 2>/dev/null; then
            trap 'rmdir "$lock_dir"' EXIT
            generate_taskview_icon_cache
        fi
    ) >/dev/null 2>&1 &
}

# =============================================================================
# MAIN LOGIC
# =============================================================================

# 1. Handle Workspace Switching & Moving directly
if [[ "$ACTION" =~ ^[0-9]+$ ]]; then
    WORKSPACE_NUM="$ACTION"
    MOVE_OPT="$2"
    
    cleanup_all
    
    if [[ "$MOVE_OPT" == "move" ]]; then
        hyprctl dispatch movetoworkspace "$WORKSPACE_NUM"
    else
        hyprctl dispatch workspace "$WORKSPACE_NUM"
    fi
    exit 0
fi

# 2. Handle Closing
if [[ "$ACTION" == "close" ]]; then
    if [[ -z "$TARGET" || "$TARGET" == "all" ]]; then
        # Close everything if no target is specified
        cleanup_all
    else
        # Close only the specific target
        get_qml_info "$TARGET"
        QML_BASE=$(basename "$QML_FILE")
        pkill -f "quickshell.*$QML_BASE"

        # If it was the network window, handle the specific bluetooth cleanup
        if [[ "$TARGET" == "network" ]]; then
            if [ -f "$BT_PID_FILE" ]; then
                kill $(cat "$BT_PID_FILE") 2>/dev/null
                rm -f "$BT_PID_FILE"
            fi
            bluetoothctl scan off > /dev/null 2>&1
        fi
    fi
    exit 0
fi

# 3. Handle Opening / Toggling specific windows
if [[ "$ACTION" == "open" || "$ACTION" == "toggle" ]]; then
    
    get_qml_info "$TARGET"
    QML_BASE=$(basename "$QML_FILE")

    # Standard handling for other popups
    # If action is 'toggle', check if it's already running
    if [[ "$ACTION" == "toggle" ]]; then
        if pgrep -f "quickshell.*$QML_BASE" > /dev/null; then
            # It's running, so close it and exit
            cleanup_all
            exit 0
        fi
    fi

    # GLOBAL RESET: Ensure exclusive behavior (only one open at a time)
    cleanup_all

    # Run the specific setup and open it
    if [[ "$TARGET" == "network" ]]; then
        handle_network_prep
    elif [[ "$TARGET" == "wallpaper" ]]; then
        handle_wallpaper_prep
    elif [[ "$TARGET" == "taskview" ]]; then
        ensure_taskview_icon_cache
    fi

    # Launch quickshell fully detached - works from non-interactive shells (EWW)
    setsid -f quickshell -p "$QS_DIR/$QML_FILE" >/dev/null 2>&1

    # Focus logic to ensure escape key works
    sleep 0.3
    hyprctl dispatch focuswindow "$FOCUS" >/dev/null 2>&1 || true

    exit 0
fi
