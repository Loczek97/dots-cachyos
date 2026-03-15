#!/bin/bash

# TaskView daemon manager

QS_DIR="/home/michal/.config/hypr/scripts/quickshell"
TASKVIEW_QML="$QS_DIR/taskView/WaffleTaskView.qml"

get_taskview_pid() {
    pgrep -f "quickshell.*WaffleTaskView\.qml" | head -1
}

start_daemon() {
    # Cleanup any duplicate processes first
    PIDS=$(pgrep -f "quickshell.*WaffleTaskView\.qml")
    if [[ -n "$PIDS" ]]; then
        echo "Cleaning up existing TaskView processes..."
        pkill -f "quickshell.*WaffleTaskView\.qml"
        sleep 0.5
    fi
    
    echo "Starting TaskView daemon..."
    cd "$QS_DIR"
    quickshell -p taskView/WaffleTaskView.qml &>/tmp/taskview-daemon.log &
    sleep 1
    
    if [[ -n "$(get_taskview_pid)" ]]; then
        echo "TaskView daemon started successfully (PID: $(get_taskview_pid))"
        return 0
    else
        echo "Failed to start TaskView daemon. Check /tmp/taskview-daemon.log"
        return 1
    fi
}

stop_daemon() {
    PIDS=$(pgrep -f "quickshell.*WaffleTaskView\.qml")
    if [[ -z "$PIDS" ]]; then
        echo "TaskView daemon not running"
        return 0
    fi
    
    echo "Stopping TaskView daemon(s)..."
    pkill -f "quickshell.*WaffleTaskView\.qml"
    echo "TaskView daemon stopped"
}

toggle_view() {
    PID=$(get_taskview_pid)
    if [[ -z "$PID" ]]; then
        echo "TaskView daemon not running. Starting..."
        start_daemon || exit 1
        PID=$(get_taskview_pid)
    fi
    
    echo "Toggling TaskView (PID: $PID)..."
    quickshell ipc --pid "$PID" call search toggle
}

case "$1" in
    start)
        start_daemon
        ;;
    stop)
        stop_daemon
        ;;
    toggle|open)
        toggle_view
        ;;
    restart)
        stop_daemon
        sleep 0.5
        start_daemon
        ;;
    status)
        PID=$(get_taskview_pid)
        if [[ -n "$PID" ]]; then
            echo "TaskView daemon is running (PID: $PID)"
        else
            echo "TaskView daemon is not running"
        fi
        ;;
    *)
        echo "Usage: $0 {start|stop|toggle|restart|status}"
        exit 1
        ;;
esac
