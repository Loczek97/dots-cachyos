#!/usr/bin/bash

sleep 30s

UPDATES=$(checkupdates 2>/dev/null | wc -l)

if [ $UPDATES -gt 0 ]; then
  notify-send -a "System" -i "system-software-update" "Dostępne aktualizacje" "Masz $UPDATES aktualizacji do zainstalowania."
else
  echo ""
fi
