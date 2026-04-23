#!/usr/bin/env bash

LOG_FILE="$HOME/.cache/quickshell_clock.log"
DATE=$(date "+%Y-%m-%d %H:%M:%S")

echo "--- Start of session: $DATE ---" >> "$LOG_FILE"
echo "Starting quickshell with DesktopClock.qml..." >> "$LOG_FILE"

# Run quickshell and redirect all output (stdout and stderr) to log
# Using -p to point to the correct QML file
/usr/bin/quickshell -p "$HOME/.config/quickshell/desktopclock/DesktopClock.qml" >> "$LOG_FILE" 2>&1 &

PID=$!
echo "Process started with PID: $PID" >> "$LOG_FILE"
