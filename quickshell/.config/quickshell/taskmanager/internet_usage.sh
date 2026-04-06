#!/bin/bash
IFACE=$(ip route get 8.8.8.8 2>/dev/null | grep -Po '(?<=dev )\S+')
[ -z "$IFACE" ] && IFACE=$(awk '{if(NR>2 && $2>0) print $1}' /proc/net/dev | cut -d ':' -f 1 | head -n 1)

STATE_FILE="/tmp/net_stat_$IFACE"
DATA=$(grep "$IFACE" /proc/net/dev | sed 's/:/ /g')
NOW_RX=$(echo $DATA | awk '{print $2}')
NOW_TX=$(echo $DATA | awk '{print $10}')

if [ -f "$STATE_FILE" ]; then
    read OLD_RX OLD_TX < "$STATE_FILE"
    # Obliczamy różnicę bajtów i mnożymy przez 8, żeby dostać bity
    echo "download: $(((NOW_RX - OLD_RX) * 8))"
    echo "upload: $(((NOW_TX - OLD_TX) * 8))"
else
    echo "download: 0"
    echo "upload: 0"
fi
echo "$NOW_RX $NOW_TX" > "$STATE_FILE"