#!/usr/bin/env bash

pkill -9 quickshell
sleep 0.5

env QS_NO_RELOAD_POPUP=1 quickshell -p ~/.config/quickshell/bar/TopBar.qml >/dev/null 2>&1 &
