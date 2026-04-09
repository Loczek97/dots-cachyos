#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# DEBUGGING & DEBOUNCE
# -----------------------------------------------------------------------------
LOG_FILE="/tmp/qs_debug.log"
TARGET="$2"
ACTION="$1"
LOCK_FILE="/tmp/qs_lock_$TARGET"

# Simple debounce: if called again for the same target within 0.5s, ignore
if [ -f "$LOCK_FILE" ]; then
    LAST_CALL=$(cat "$LOCK_FILE")
    CUR_TIME=$(date +%s%3N)
    DIFF=$((CUR_TIME - LAST_CALL))
    if [ $DIFF -lt 500 ]; then
        echo "Debounce: Ignoring double-call for $TARGET (diff: ${DIFF}ms)" >> "$LOG_FILE"
        exit 0
    fi
fi
date +%s%3N > "$LOCK_FILE"

echo "--- $(date) ---" >> "$LOG_FILE"
echo "Call: $0 $@" >> "$LOG_FILE"

# -----------------------------------------------------------------------------
# CONSTANTS & ARGUMENTS
# -----------------------------------------------------------------------------
QS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BT_PID_FILE="$HOME/.cache/bt_scan_pid"
BT_SCAN_LOG="$HOME/.cache/bt_scan.log"
SRC_DIR="$HOME/.config/backgrounds"
THUMB_DIR="$HOME/.cache/wallpaper_picker/thumbs"

SUBTARGET="$3"
QS_CONFIG="$HOME/.config/quickshell"

# -----------------------------------------------------------------------------
# FAST PATH: WORKSPACE SWITCHING
# -----------------------------------------------------------------------------
if [[ "$ACTION" =~ ^[0-9]+$ ]]; then
    WORKSPACE_NUM="$ACTION"
    MOVE_OPT="$2"
    
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

# -----------------------------------------------------------------------------
# PREP FUNCTIONS
# -----------------------------------------------------------------------------
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

# -----------------------------------------------------------------------------
# WATCHDOG: Ensure TopBar is alive
# -----------------------------------------------------------------------------
TOPBAR_QML="$QS_CONFIG/bar/TopBar.qml"
BAR_PID=$(pgrep -u $USER -x quickshell | while read pid; do if ps -fp "$pid" | grep -q "bar/TopBar\.qml"; then echo "$pid"; break; fi; done)

if [[ -z "$BAR_PID" ]] && [[ -f "$TOPBAR_QML" ]] && [[ "$ACTION" != "restart" ]] && [[ "$ACTION" != "close" ]]; then
    echo "Starting TopBar because BAR_PID is empty" >> "$LOG_FILE"
    QS_NO_RELOAD_POPUP=1 quickshell -p "$TOPBAR_QML" >> "$LOG_FILE" 2>&1 &
    disown
    sleep 0.3
fi

if [[ "$ACTION" == "restart" ]]; then
    pkill -u $USER -x quickshell 2>/dev/null
    sleep 0.5
    if [[ -f "$TOPBAR_QML" ]]; then
        QS_NO_RELOAD_POPUP=1 quickshell -p "$TOPBAR_QML" >> "$LOG_FILE" 2>&1 &
        disown
    fi
    exit 0
fi

# -----------------------------------------------------------------------------
# MAIN LOGIC
# -----------------------------------------------------------------------------
if [[ "$ACTION" == "close" ]]; then
    echo "Action: close" >> "$LOG_FILE"
    if [[ "$TARGET" == "network" || "$TARGET" == "all" || -z "$TARGET" ]]; then
        if [ -f "$BT_PID_FILE" ]; then
            kill $(cat "$BT_PID_FILE") 2>/dev/null
            rm -f "$BT_PID_FILE"
        fi
        bluetoothctl scan off > /dev/null 2>&1
    fi
    # Kill all popups aggressively
    pkill -9 -u $USER -f "quickshell.*Popup.qml" 2>/dev/null
    pkill -9 -u $USER -f "quickshell.*TaskManager.qml" 2>/dev/null
    pkill -9 -u $USER -f "quickshell.*WallpaperPicker.qml" 2>/dev/null
    exit 0
fi

if [[ "$ACTION" == "open" || "$ACTION" == "toggle" ]]; then
    case "$TARGET" in
        calendar)     QML="calendar/CalendarPopup.qml" ;;
        music)        QML="music/MusicPopup.qml" ;;
        battery)      QML="battery/BatteryPopup.qml" ;;
        network)      QML="network/NetworkPopup.qml"; handle_network_prep ;;
        taskmanager)  QML="taskmanager/TaskManager.qml" ;;
        mixer)        QML="mixer/MixerPopup.qml" ;;
        dashboard)    QML="dashboard/DashboardPopup.qml" ;;
        wallpaper)    QML="wallpaper/WallpaperPicker.qml"; handle_wallpaper_prep ;;
        *)            echo "Unknown target: $TARGET" >> "$LOG_FILE"; exit 1 ;;
    esac

    FULL_PATH="$QS_CONFIG/$QML"
    if [ ! -f "$FULL_PATH" ]; then
        echo "Error: File $FULL_PATH not found" >> "$LOG_FILE"
        exit 1
    fi

    # FIND PROCESS: Must be 'quickshell' AND have our QML in arguments
    POPUP_PID=$(pgrep -u $USER -x quickshell | while read pid; do
        if ps -fp "$pid" | grep -qE "\-p.*$QML"; then
            echo "$pid"
            break
        fi
    done)

    if [[ -n "$POPUP_PID" ]]; then
        # Check if the window actually exists in Hyprland
        # Quickshell windows usually have a title or class we can find
        HAS_WINDOW=$(hyprctl clients -j | jq -r ".[] | select(.pid == $POPUP_PID) | .address")
        
        if [[ -z "$HAS_WINDOW" ]]; then
            echo "Found PID $POPUP_PID but NO WINDOW. Zombie process. Killing -9." >> "$LOG_FILE"
            kill -9 "$POPUP_PID" 2>/dev/null
            POPUP_PID="" # Clear it so we start a new one below
        elif [[ "$ACTION" == "toggle" ]]; then
            echo "Action: toggle -> Found legitimate PID $POPUP_PID. Killing it." >> "$LOG_FILE"
            kill "$POPUP_PID" 2>/dev/null
            # If still alive after 0.5s, force kill
            (sleep 0.5; kill -9 "$POPUP_PID" 2>/dev/null) &
            exit 0
        else
            echo "Action: open -> Already running with window (PID $POPUP_PID), doing nothing" >> "$LOG_FILE"
            exit 0
        fi
    fi

    if [[ -z "$POPUP_PID" ]]; then
        echo "Action: $ACTION -> Starting quickshell -p $FULL_PATH" >> "$LOG_FILE"
        # Ensure any lingering same-named processes are gone
        pkill -9 -u $USER -f "quickshell.*$QML" 2>/dev/null
        
        QS_NO_RELOAD_POPUP=1 quickshell -p "$FULL_PATH" >> "$LOG_FILE" 2>&1 &
        disown
    fi
    exit 0
fi
