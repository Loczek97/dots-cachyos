#!/usr/bin/env bash

# Decisive swaync reload for Matugen - full restart to guarantee fresh CSS load
# Longer waits to ensure matugen completes its work

LOG="/tmp/swaync_reload.log"

{
    echo "[$(date '+%H:%M:%S')] Starting swaync reload..."
    
    # 1. Wait longer for matugen to finish writing files
    sleep 1.0
    
    # 2. Aggressive kill of swaync
    killall -9 swaync 2>/dev/null || true
    sleep 0.4
    
    # 3. Wait for process exit
    timeout 2 bash -c 'while pgrep swaync >/dev/null; do sleep 0.05; done' 2>/dev/null || true
    sleep 0.3
    
    # 4. Start fresh swaync - this will load fresh CSS from disk
    echo "[$(date '+%H:%M:%S')] Starting swaync fresh..."
    setsid -f swaync -c "$HOME/.config/swaync/config.json" &>/dev/null
    
    # 5. Verify it started
    timeout 3 bash -c 'while ! pgrep swaync >/dev/null; do sleep 0.1; done' 2>/dev/null || true
    
    if pgrep swaync >/dev/null 2>&1; then
        echo "[$(date '+%H:%M:%S')] ✓ swaync restarted with fresh CSS"
    else
        echo "[$(date '+%H:%M:%S')] ✗ swaync failed to start"
    fi
} >> "$LOG" 2>&1 &
