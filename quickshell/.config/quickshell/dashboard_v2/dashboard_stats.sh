#!/usr/bin/env bash
export LC_ALL=C

# --- CPU USAGE ---
# Odczyt z /proc/stat
CPU_STATE="/tmp/qs_dash_cpu_state"
if [ -f "$CPU_STATE" ]; then
    read -r last_total last_idle < "$CPU_STATE"
else
    last_total=0
    last_idle=0
fi

read -r -a cpu_fields < <(grep '^cpu ' /proc/stat)
# total = user + nice + system + idle + iowait + irq + softirq + steal
total=0
for val in "${cpu_fields[@]:1}"; do
    total=$((total + val))
done
idle=${cpu_fields[4]}

echo "$total $idle" > "$CPU_STATE"

total_diff=$((total - last_total))
idle_diff=$((idle - last_idle))

if [ $total_diff -gt 0 ]; then
    CPU_USAGE=$(( 100 * (total_diff - idle_diff) / total_diff ))
else
    CPU_USAGE=0
fi

# --- CPU TEMP ---
CPU_TEMP=0
if command -v sensors &> /dev/null; then
    CPU_TEMP=$(sensors | grep -E 'Tctl|Package id 0' | head -n 1 | awk '{print $2}' | tr -d '+°C' | cut -d. -f1)
    [ -z "$CPU_TEMP" ] && CPU_TEMP=$(sensors | grep 'temp1' | head -n 1 | awk '{print $2}' | tr -d '+°C' | cut -d. -f1)
fi
if [ -z "$CPU_TEMP" ] || [ "$CPU_TEMP" = "0" ]; then
    for tz in /sys/class/thermal/thermal_zone*; do
        if [ -f "$tz/temp" ] && [ -f "$tz/type" ]; then
            type=$(cat "$tz/type")
            if [[ "$type" =~ x86_pkg_temp|cpu ]]; then
                temp=$(cat "$tz/temp")
                CPU_TEMP=$((temp / 1000))
                break
            fi
        fi
    done
fi
if [ -z "$CPU_TEMP" ] || [ "$CPU_TEMP" = "0" ]; then
    if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
        CPU_TEMP=$(( $(cat /sys/class/thermal/thermal_zone0/temp) / 1000 ))
    fi
fi
[ -z "$CPU_TEMP" ] && CPU_TEMP=0

# --- RAM ---
RAM_DATA=$(free -m | grep Mem | awk '{print $2 " " $3}')
RAM_TOTAL_MB=$(echo $RAM_DATA | awk '{print $1}')
RAM_USED_MB=$(echo $RAM_DATA | awk '{print $2}')
RAM_USAGE=$((RAM_USED_MB * 100 / RAM_TOTAL_MB))

RAM_USED_GB=$(printf "%.1fG" $(echo "scale=2; $RAM_USED_MB / 1024" | bc) | tr -d '\r\n')
RAM_TOTAL_GB=$(printf "%.1fG" $(echo "scale=2; $RAM_TOTAL_MB / 1024" | bc) | tr -d '\r\n')

# --- DISK ---
DISK_DATA=$(df -m / | tail -n 1 | awk '{print $2 " " $3 " " $5}')
DISK_TOTAL_MB=$(echo $DISK_DATA | awk '{print $1}')
DISK_USED_MB=$(echo $DISK_DATA | awk '{print $2}')
DISK_USAGE=$(echo $DISK_DATA | awk '{print $3}' | tr -d '%')

DISK_USED_GB=$(printf "%.0fG" $(echo "scale=2; $DISK_USED_MB / 1024" | bc) | tr -d '\r\n')
DISK_TOTAL_GB=$(printf "%.0fG" $(echo "scale=2; $DISK_TOTAL_MB / 1024" | bc) | tr -d '\r\n')

# --- GPU TEMP ---
GPU_TEMP=0
if command -v nvidia-smi &> /dev/null; then
    GPU_TEMP=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | tr -d ' ')
fi
[ -z "$GPU_TEMP" ] && GPU_TEMP=0

# --- UPTIME ---
UPTIME_SEC=$(awk '{print int($1)}' /proc/uptime)
UPTIME_DAYS=$((UPTIME_SEC / 86400))
UPTIME_HOURS=$(( (UPTIME_SEC % 86400) / 3600 ))
UPTIME_MINS=$(( (UPTIME_SEC % 3600) / 60 ))

# Zwracanie JSON
echo "{\"cpu_usage\":$CPU_USAGE,\"cpu_temp\":$CPU_TEMP,\"ram_usage\":$RAM_USAGE,\"ram_used\":\"$RAM_USED_GB\",\"ram_total\":\"$RAM_TOTAL_GB\",\"disk_usage\":$DISK_USAGE,\"disk_used\":\"$DISK_USED_GB\",\"disk_total\":\"$DISK_TOTAL_GB\",\"gpu_temp\":$GPU_TEMP,\"uptime_days\":$UPTIME_DAYS,\"uptime_hours\":$UPTIME_HOURS,\"uptime_minutes\":$UPTIME_MINS}"
