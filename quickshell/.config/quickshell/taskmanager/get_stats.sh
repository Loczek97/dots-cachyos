#!/bin/bash
export LC_ALL=C

# --- PREPARE TEMP FILES FOR NETWORK ---
NET_STATE="/tmp/qs_net_state"
NOW=$(date +%s.%N)

INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n 1)
[ -z "$INTERFACE" ] && INTERFACE="eth0"

READ_NET=$(grep "$INTERFACE" /proc/net/dev | awk '{print $2 " " $10}')
RX_NOW=$(echo $READ_NET | awk '{print $1}')
TX_NOW=$(echo $READ_NET | awk '{print $2}')

if [ -f "$NET_STATE" ]; then
    read LAST_TIME LAST_RX LAST_TX < "$NET_STATE"
    TIME_DIFF=$(echo "$NOW - $LAST_TIME" | bc)
    DOWNLOAD=$(echo "($RX_NOW - $LAST_RX) * 8 / $TIME_DIFF" | bc)
    UPLOAD=$(echo "($TX_NOW - $LAST_TX) * 8 / $TIME_DIFF" | bc)
else
    DOWNLOAD=0
    UPLOAD=0
fi
echo "$NOW $RX_NOW $TX_NOW" > "$NET_STATE"

# --- CPU & RAM (Global) ---
CPU_STATE="/tmp/qs_cpu_state"
declare -a LAST_CPU
if [ -f "$CPU_STATE" ]; then
    LAST_CPU=($(cat "$CPU_STATE"))
fi

NOW_CPU=($(grep '^cpu[0-9]' /proc/stat | awk '{print $2+$3+$4+$5+$6+$7+$8" "$5}'))
echo "${NOW_CPU[@]}" > "$CPU_STATE"

CORES_JSON="[]"
if [ ${#LAST_CPU[@]} -gt 0 ]; then
    CORES_JSON=$(awk -v now="${NOW_CPU[*]}" -v last="${LAST_CPU[*]}" '
    BEGIN {
        split(now, n); split(last, l);
        printf "[";
        for (i=1; i<=length(n); i+=2) {
            total_diff = n[i] - l[i];
            idle_diff = n[i+1] - l[i+1];
            usage = (total_diff > 0) ? 100 * (total_diff - idle_diff) / total_diff : 0;
            if (usage < 0) usage = 0;
            if (usage > 100) usage = 100;
            printf "%.1f%s", usage, (i+2 > length(n) ? "" : ",");
        }
        printf "]";
    }')
fi

CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4 + $6}')
[ -z "$CPU" ] && CPU=0
RAM=$(free | grep Mem | awk '{if ($2 > 0) print $3/$2 * 100.0; else print 0}')
[ -z "$RAM" ] && RAM=0

# --- NVIDIA GPU ---
if command -v nvidia-smi &> /dev/null; then
    GPU_DATA=$(nvidia-smi --query-gpu=utilization.gpu,utilization.memory,temperature.gpu --format=csv,noheader,nounits | tr -d ' ')
    GPU_UTIL=$(echo $GPU_DATA | cut -d',' -f1)
    GPU_MEM_UTIL=$(echo $GPU_DATA | cut -d',' -f2)
    GPU_TEMP=$(echo $GPU_DATA | cut -d',' -f3)
else
    GPU_UTIL=0
    GPU_MEM_UTIL=0
    GPU_TEMP=0
fi

# --- CPU TEMP ---
if command -v sensors &> /dev/null; then
    CPU_TEMP=$(sensors | grep -E 'Tctl|Package id 0' | head -n 1 | awk '{print $2}' | tr -d '+°C')
    [ -z "$CPU_TEMP" ] && CPU_TEMP=$(sensors | grep 'temp1' | head -n 1 | awk '{print $2}' | tr -d '+°C')
else
    CPU_TEMP=0
fi
[ -z "$CPU_TEMP" ] && CPU_TEMP=0

# --- PROCESSES (Real-time CPU using top) ---
# We use top in batch mode with 2 iterations to get accurate CURRENT usage.
# But 2 iterations take too long for a UI script.
# Alternative: Use ps with --sort=-%cpu, but normalize by number of cores.
NUM_CORES=$(nproc)
PROCS=$(ps -eo pid,comm,%cpu,%mem,rss --sort=-%cpu --no-headers | head -n 50 | awk -v cores="$NUM_CORES" '
BEGIN { first=1; printf "[" }
{
    pid = $1; name = $2; 
    # ps %cpu is sum of all cores. Normalize by core count to match btop/top.
    cpu = $3 / cores; 
    mem_perc = $4; rss = $5;
    
    gsub(/\\/, "\\\\", name); gsub(/"/, "\\\"", name);
    mem_mb = rss / 1024;
    
    if (!first) printf ",";
    printf "{\"pid\":%d,\"name\":\"%s\",\"cpu\":%.1f,\"mem\":%.1f,\"mem_mb\":%.1f}", pid, name, cpu, mem_perc, mem_mb;
    first=0;
}
END { printf "]" }
')

echo "{\"cpu\": $CPU, \"ram\": $RAM, \"down\": $DOWNLOAD, \"up\": $UPLOAD, \"gpu\": $GPU_UTIL, \"gpu_mem\": $GPU_MEM_UTIL, \"cpu_temp\": $CPU_TEMP, \"gpu_temp\": $GPU_TEMP, \"processes\": $PROCS, \"cpu_cores\": $CORES_JSON}"
