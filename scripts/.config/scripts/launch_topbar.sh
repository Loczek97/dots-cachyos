#!/usr/bin/env bash

# Wymuszone ubicie Quickshella
pkill -9 quickshell
sleep 0.5

# Odpalenie paska raz (na głównym monitorze)
env QS_NO_RELOAD_POPUP=1 quickshell -p ~/.config/quickshell/TopBar/TopBar.qml > /dev/null 2>&1 &
