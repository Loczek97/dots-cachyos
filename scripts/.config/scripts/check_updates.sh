#!/usr/bin/bash

UPDATES=$(checkupdates 2>/dev/null | wc -l)

if [ $UPDATES -gt 0 ]; then
    notify-send "Dostępne aktualizacje" "Masz $UPDATES aktualizacji do zainstalowania."
else
    echo ""
fi