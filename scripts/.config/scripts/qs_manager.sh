#!/usr/bin/env bash

QS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BT_PID_FILE="$HOME/.cache/bt_scan_pid"
BT_SCAN_LOG="$HOME/.cache/bt_scan.log"
SRC_DIR="$HOME/.config/backgrounds"
THUMB_DIR="$HOME/.cache/wallpaper_picker/thumbs"

IPC_FILE="/tmp/qs_widget_state"
NETWORK_MODE_FILE="/tmp/qs_network_mode"
ACTION="$1"
TARGET="$2"
SUBTARGET="$3"
QS_CONFIG="${QS_DIR%/*}/quickshell"

handle_wallpaper_prep() {
    mkdir -p "$THUMB_DIR"
    (
        for thumb in "$THUMB_DIR"/*; do
            [ -e "$thumb" ] || continue
            filename=$(basename "$thumb")
            clean_name="${filename#000_}"
            if [ ! -f "$SRC_DIR/$clean_name" ]; then
                rm -f "$thumb"
            fi
        done

        for img in "$SRC_DIR"/*.{jpg,jpeg,png,webp,gif,mp4,mkv,mov,webm}; do
            [ -e "$img" ] || continue
            filename=$(basename "$img")
            extension="${filename##*.}"

            if [[ "${extension,,}" =~ ^(mp4|mkv|mov|webm)$ ]]; then
                thumb="$THUMB_DIR/000_$filename"
                [ -f "$THUMB_DIR/$filename" ] && rm -f "$THUMB_DIR/$filename"
                if [ ! -f "$thumb" ]; then
                     ffmpeg -y -ss 00:00:05 -i "$img" -vframes 1 -f image2 -q:v 2 "$thumb" > /dev/null 2>&1
                fi
            else
                thumb="$THUMB_DIR/$filename"
                if [ ! -f "$thumb" ]; then
                    magick "$img" -resize x420 -quality 70 "$thumb"
                fi
            fi
        done
    ) &

    TARGET_THUMB=""
    CURRENT_SRC=""

    if pgrep -a "mpvpaper" > /dev/null; then
        CURRENT_SRC=$(pgrep -a mpvpaper | grep -o "$SRC_DIR/[^' ]*" | head -n1)
        CURRENT_SRC=$(basename "$CURRENT_SRC")
    fi

    if [ -z "$CURRENT_SRC" ] && command -v swww >/dev/null; then
        CURRENT_SRC=$(swww query 2>/dev/null | grep -o "$SRC_DIR/[^ ]*" | head -n1)
        CURRENT_SRC=$(basename "$CURRENT_SRC")
    fi

    if [ -n "$CURRENT_SRC" ]; then
        EXT="${CURRENT_SRC##*.}"
        if [[ "${EXT,,}" =~ ^(mp4|mkv|mov|webm)$ ]]; then
            TARGET_THUMB="000_$CURRENT_SRC"
        else
            TARGET_THUMB="$CURRENT_SRC"
        fi
    fi
    
    export WALLPAPER_THUMB="$TARGET_THUMB"
}

handle_network_prep() {
    echo "" > "$BT_SCAN_LOG"
    { echo "scan on"; sleep infinity; } | stdbuf -oL bluetoothctl > "$BT_SCAN_LOG" 2>&1 &
    echo $! > "$BT_PID_FILE"
    (nmcli device wifi rescan) &
}

# Ensure TopBar is alive (used by matugen reload hooks too)
TOPBAR_QML="$QS_CONFIG/bar/TopBar.qml"
BAR_PID=$(pgrep -f "quickshell.*bar/TopBar\.qml")

if [[ -z "$BAR_PID" ]] && [[ -f "$TOPBAR_QML" ]]; then
    QS_NO_RELOAD_POPUP=1 quickshell -p "$TOPBAR_QML" >/dev/null 2>&1 &
    disown
fi

if [[ "$ACTION" == "restart" ]]; then
    pkill -f "quickshell.*bar/TopBar\.qml" 2>/dev/null
    if [[ -f "$TOPBAR_QML" ]]; then
        QS_NO_RELOAD_POPUP=1 quickshell -p "$TOPBAR_QML" >/dev/null 2>&1 &
        disown
        exit 0
    fi
    exit 1
fi

# -----------------------------------------------------------------------------
# MAIN LOGIC
# -----------------------------------------------------------------------------
if [[ "$ACTION" =~ ^[0-9]+$ ]]; then
    WORKSPACE_NUM="$ACTION"
    MOVE_OPT="$2"
    echo "close" > "$IPC_FILE"
    
    if [[ "$MOVE_OPT" == "move" ]]; then
        hyprctl dispatch movetoworkspace "$WORKSPACE_NUM"
    else
        hyprctl dispatch workspace "$WORKSPACE_NUM"
    fi

    TARGET_ADDR=$(hyprctl clients -j | jq -r ".[] | select(.workspace.id == $WORKSPACE_NUM and (.class | contains(\"qs-master\") | not) and (.title | contains(\"qs-master\") | not)) | .address" | head -n 1)

    if [[ -n "$TARGET_ADDR" && "$TARGET_ADDR" != "null" ]]; then
        hyprctl --batch "keyword cursor:no_warps true ; dispatch focuswindow address:$TARGET_ADDR ; keyword cursor:no_warps false"
    else
        hyprctl --batch "keyword cursor:no_warps true ; dispatch focuswindow qs-master ; keyword cursor:no_warps false"
    fi

    exit 0
fi

if [[ "$ACTION" == "close" ]]; then
    echo "close" > "$IPC_FILE"
    if [[ "$TARGET" == "network" || "$TARGET" == "all" || -z "$TARGET" ]]; then
        if [ -f "$BT_PID_FILE" ]; then
            kill $(cat "$BT_PID_FILE") 2>/dev/null
            rm -f "$BT_PID_FILE"
        fi
        bluetoothctl scan off > /dev/null 2>&1
    fi
    exit 0
fi

if [[ "$ACTION" == "open" || "$ACTION" == "toggle" ]]; then
    # Handle popup windows (calendar, music, battery, network)
    if [[ "$TARGET" == "calendar" ]]; then
        POPUP_PID=$(pgrep -f "quickshell.*CalendarPopup.qml" 2>/dev/null)
        if [[ -n "$POPUP_PID" ]] && [[ "$ACTION" == "toggle" ]]; then
            kill $POPUP_PID 2>/dev/null
        else
            [ ! -d "$QS_CONFIG/calendar" ] && exit 1
            quickshell -p "$QS_CONFIG/calendar/CalendarPopup.qml" >/dev/null 2>&1 &
            disown
        fi
        exit 0
    fi

    if [[ "$TARGET" == "music" ]]; then
        POPUP_PID=$(pgrep -f "quickshell.*MusicPopup.qml" 2>/dev/null)
        if [[ -n "$POPUP_PID" ]] && [[ "$ACTION" == "toggle" ]]; then
            kill $POPUP_PID 2>/dev/null
        else
            [ ! -d "$QS_CONFIG/music" ] && exit 1
            quickshell -p "$QS_CONFIG/music/MusicPopup.qml" >/dev/null 2>&1 &
            disown
        fi
        exit 0
    fi

    if [[ "$TARGET" == "battery" ]]; then
        POPUP_PID=$(pgrep -f "quickshell.*BatteryPopup.qml" 2>/dev/null)
        if [[ -n "$POPUP_PID" ]] && [[ "$ACTION" == "toggle" ]]; then
            kill $POPUP_PID 2>/dev/null
        else
            [ ! -d "$QS_CONFIG/battery" ] && exit 1
            quickshell -p "$QS_CONFIG/battery/BatteryPopup.qml" >/dev/null 2>&1 &
            disown
        fi
        exit 0
    fi

    if [[ "$TARGET" == "network" ]]; then
        POPUP_PID=$(pgrep -f "quickshell.*NetworkPopup.qml" 2>/dev/null)
        if [[ -n "$POPUP_PID" ]] && [[ "$ACTION" == "toggle" ]]; then
            kill $POPUP_PID 2>/dev/null
        else
            [ ! -d "$QS_CONFIG/network" ] && exit 1
            handle_network_prep &
            quickshell -p "$QS_CONFIG/network/NetworkPopup.qml" >/dev/null 2>&1 &
            disown
        fi
        exit 0
    fi

    if [[ "$TARGET" == "taskmanager" ]]; then
        POPUP_PID=$(pgrep -f "quickshell.*taskmanager/TaskManager.qml" 2>/dev/null)
        if [[ -n "$POPUP_PID" ]] && [[ "$ACTION" == "toggle" ]]; then
            kill $POPUP_PID 2>/dev/null
        else
            [ ! -d "$QS_CONFIG/taskmanager" ] && exit 1
            quickshell -p "$QS_CONFIG/taskmanager/TaskManager.qml" >/dev/null 2>&1 &
            disown
        fi
        exit 0
    fi

    if [[ "$TARGET" == "mixer" ]]; then
        POPUP_PID=$(pgrep -f "quickshell.*mixer/MixerPopup.qml" 2>/dev/null)
        if [[ -n "$POPUP_PID" ]] && [[ "$ACTION" == "toggle" ]]; then
            kill $POPUP_PID 2>/dev/null
        else
            [ ! -d "$QS_CONFIG/mixer" ] && exit 1
            quickshell -p "$QS_CONFIG/mixer/MixerPopup.qml" >/dev/null 2>&1 &
            disown
        fi
        exit 0
    fi

    if [[ "$TARGET" == "wallpaper" ]]; then
        PICKER_QML="$QS_CONFIG/wallpaper/WallpaperPicker.qml"
        POPUP_PID=$(pgrep -f "quickshell.*WallpaperPicker\.qml" 2>/dev/null)

        if [[ -n "$POPUP_PID" ]] && [[ "$ACTION" == "toggle" ]]; then
            pkill -f "quickshell.*WallpaperPicker\.qml" 2>/dev/null
        else
            [ ! -f "$PICKER_QML" ] && exit 1
            handle_wallpaper_prep
            quickshell -p "$PICKER_QML" >/dev/null 2>&1 &
            disown
        fi
    else
        echo "$TARGET" > "$IPC_FILE"
    fi
    exit 0
fi